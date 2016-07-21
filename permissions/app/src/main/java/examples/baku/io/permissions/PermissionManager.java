// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package examples.baku.io.permissions;

import com.google.common.collect.HashBasedTable;
import com.google.common.collect.HashMultimap;
import com.google.common.collect.Multimap;
import com.google.common.collect.Sets;
import com.google.common.collect.Table;
import com.google.firebase.database.ChildEventListener;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.ValueEventListener;

import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import examples.baku.io.permissions.util.Utils;


/**
 * Created by phamilton on 6/28/16.
 */
public class PermissionManager {

    public static final String EXTRA_TIMEOUT = "extraTimeout";
    public static final String EXTRA_COLOR = "extraColor";
    private DatabaseReference mDatabaseRef;
    private DatabaseReference mBlessingsRef;
    private DatabaseReference mRequestsRef;

    public static final int FLAG_DEFAULT = 0;
    public static final int FLAG_WRITE = 1 << 0;
    public static final int FLAG_READ = 1 << 1;
    public static final int FLAG_SUGGEST = 1 << 2;
    public static final int FLAG_ROOT = Integer.MAX_VALUE;

    static final String KEY_PERMISSIONS = "_permissions";
    static final String KEY_REQUESTS = "_requests";
    static final String KEY_BLESSINGS = "_blessings";

    private static final String KEY_ROOT = "root";

    private String mId;
    private Blessing rootBlessing;

    //<blessing id, blessing>
    private final Map<String, Blessing> mBlessings = new HashMap<>();
    //<source, target, blessing>
    private final Table<String, String, Blessing> mBlessingsTable = HashBasedTable.create();
    private final Set<String> mBlessingTargets = new HashSet();

    private final Map<String, PermissionRequest> mRequests = new HashMap<>();
    private final Table<String, String, PermissionRequest.Builder> mActiveRequests = HashBasedTable.create();

    private final Multimap<String, OnRequestListener> mRequestListeners = HashMultimap.create(); //<path,, >
    private final Multimap<String, OnRequestListener> mSubscribedRequests = HashMultimap.create(); //<requestDialog id, >

    private Blessing.PermissionTree mPermissionTree = new Blessing.PermissionTree();
    private final Multimap<String, OnPermissionChangeListener> mPermissionValueEventListeners = HashMultimap.create();
    private final Multimap<String, String> mNearestAncestors = HashMultimap.create();


    //TODO: replace string ownerId with Auth
    public PermissionManager(final DatabaseReference databaseReference, String owner) {
        this.mDatabaseRef = databaseReference;
        this.mId = owner;

        mRequestsRef = databaseReference.child(KEY_REQUESTS);
        //TODO: only consider requests from sources within the constellation
        mRequestsRef.addChildEventListener(requestListener);
        mBlessingsRef = mDatabaseRef.child(KEY_BLESSINGS);

        this.mId = owner;
        initRootBlessing();
        join(mId);

    }

    public void join(String group) {
        mBlessingsRef.orderByChild("target").equalTo(group).addChildEventListener(blessingListener);
        mBlessingTargets.add(group);
    }

    public void leave(String group) {
        mBlessingsRef.orderByChild("target").equalTo(group).removeEventListener(blessingListener);
        mBlessingTargets.remove(group);
    }

    public void initRootBlessing() {
        rootBlessing = Blessing.createRoot(this, mId);
    }

    //TODO: optimize this mess. Currently, recalculating entire permission tree.
    void refreshPermissions() {
        Blessing.PermissionTree updatedPermissionTree = new Blessing.PermissionTree();
        //received blessings
        for (Blessing blessing : getReceivedBlessings()) {
            if (blessing.isSynched()) {
                updatedPermissionTree.merge(blessing.getPermissionTree());
            }
        }

        //re-associate listeners with rules
        mNearestAncestors.clear();
        for (String path : mPermissionValueEventListeners.keySet()) {
            String nearestAncestor = Utils.getNearestCommonAncestor(path, updatedPermissionTree.keySet());
            if (nearestAncestor != null) {
                mNearestAncestors.put(nearestAncestor, path);
            }
        }

        Set<String> changedPermissions = new HashSet<>();

        //determine removed permissions
        Sets.SetView<String> removedPermissions = Sets.difference(mPermissionTree.keySet(), updatedPermissionTree.keySet());
        for (String path : removedPermissions) {
            String newPath = Utils.getNearestCommonAncestor(path, updatedPermissionTree.keySet());
            int previous = mPermissionTree.getPermissions(path);
            int current = updatedPermissionTree.getPermissions(newPath);
            if (previous != current) {
                changedPermissions.add(newPath);
            }
        }

        //compare previous tree
        for (Blessing.Permission permission : updatedPermissionTree.values()) {
            int previous = mPermissionTree.getPermissions(permission.path);
            int current = updatedPermissionTree.getPermissions(permission.path);
            if (previous != current) {
                changedPermissions.add(permission.path);
            }
        }

        mPermissionTree = updatedPermissionTree;

        //notify listeners
        for (String path : changedPermissions) {
            onPermissionsChange(path);
        }


    }

    //call all the listeners effected by a permission change at this path
    void onPermissionsChange(String path) {
        int permission = getPermissions(path);
        if (mNearestAncestors.containsKey(path)) {
            for (String listenerPath : mNearestAncestors.get(path)) {
                if (mPermissionValueEventListeners.containsKey(listenerPath)) {
                    for (OnPermissionChangeListener listener : mPermissionValueEventListeners.get(listenerPath)) {
                        listener.onPermissionChange(permission);
                    }
                }
            }
        }
    }

    public Set<PermissionRequest> getRequests(String path) {
        Set<PermissionRequest> result = new HashSet<>();
        for (PermissionRequest request : mRequests.values()) {
            if (getAllPaths(request.getPath()).contains(path)) {
                result.add(request);
            }
        }
        return result;
    }

    public PermissionRequest getRequest(String rId) {
        return mRequests.get(rId);
    }


    public Blessing getRootBlessing() {
        return rootBlessing;
    }

    public Set<Blessing> getReceivedBlessings() {
        Set<Blessing> result = new HashSet<>();
        for (String target : mBlessingTargets) {
            result.addAll(mBlessingsTable.column(target).values());
        }
        return result;
    }

    public Set<Blessing> getGrantedBlessings(String src) {
        return new HashSet<>(mBlessingsTable.row(src).values());
    }

    public Blessing putBlessing(Blessing blessing) {
        String source = blessing.getSource();
        String target = blessing.getTarget();
        mBlessings.put(blessing.getId(), blessing);
        if (source == null) {
            source = KEY_ROOT;
        }
        return mBlessingsTable.put(source, target, blessing);
    }

    public Blessing getBlessing(String id) {
        return mBlessings.get(id);
    }

    public Blessing getBlessing(String source, String target) {
        if (source == null) {
            source = KEY_ROOT;
        }
        return mBlessingsTable.get(source, target);
    }

    public void removeBlessing(String rId) {
        Blessing removedBlessing = mBlessings.remove(rId);
        if (removedBlessing != null) {
            mBlessingsTable.remove(removedBlessing.getSource(), removedBlessing.getTarget());

        }
    }

    //return a blessing interface for granting/revoking permissions
    //uses local device blessing as root
    public Blessing bless(String target) {
        return rootBlessing.bless(target);
    }

    public DatabaseReference getBlessingsRef() {
        return mBlessingsRef;
    }

    private ChildEventListener requestListener = new ChildEventListener() {
        @Override
        public void onChildAdded(DataSnapshot dataSnapshot, String s) {
            onRequestUpdated(dataSnapshot);
        }

        @Override
        public void onChildChanged(DataSnapshot dataSnapshot, String s) {
            onRequestUpdated(dataSnapshot);
        }

        @Override
        public void onChildRemoved(DataSnapshot dataSnapshot) {
            onRequestRemoved(dataSnapshot);
        }

        @Override
        public void onChildMoved(DataSnapshot dataSnapshot, String s) {

        }

        @Override
        public void onCancelled(DatabaseError databaseError) {

        }
    };

    public void finishRequest(String rId) {
        //TODO: notify source entity and ignore instead of removing
        mRequestsRef.child(rId).removeValue();
    }

    public void grantRequest(PermissionRequest request) {
        Blessing blessing = bless(request.getSource());
        blessing.setPermissions(request.getPath(), request.getPermissions());
        finishRequest(request.getId());
    }

    private void onRequestUpdated(DataSnapshot snapshot) {
        if (!snapshot.exists()) {
            return;
        }

        PermissionRequest request = snapshot.getValue(PermissionRequest.class);
        if (request == null) {
            return;
        }

        String requestPath = request.getPath();
        if (requestPath == null) {
            return;
        }

        //ignore local requests
        if (mId.equals(request.getSource())) {
            return;
        }

        //Check if request permissions can be granted by this instance
        if ((getPermissions(requestPath) & request.getPermissions()) != request.getPermissions()) {
            return;
        }

        String rId = request.getId();
        String source = request.getSource();
        mRequests.put(rId, request);

        if (mSubscribedRequests.containsKey(rId)) {
            for (OnRequestListener listener : new HashSet<>(mSubscribedRequests.get(rId))) {
                if (!listener.onRequest(request, bless(source))) {
                    //cancel subscription
                    mSubscribedRequests.remove(rId, listener);
                }
            }
        } else {
            for (String path : getAllPaths(request.getPath())) {
                for (OnRequestListener listener : mRequestListeners.get(path)) {
                    if (listener.onRequest(request, bless(source))) {
                        //add subscription
                        mSubscribedRequests.put(request.getId(), listener);
                    }
                }
            }
        }
    }

    private void onRequestRemoved(DataSnapshot snapshot) {
        mRequests.remove(snapshot.getKey());
        PermissionRequest request = snapshot.getValue(PermissionRequest.class);
        String source = request.getSource();
        if (request != null && !mId.equals(source)) {    //ignore local requests
            for (OnRequestListener listener : mSubscribedRequests.removeAll(request.getId())) {
                listener.onRequestRemoved(request, bless(source));
            }
        }
    }

    //allows
    private Set<String> getAllPaths(String path) {
        Set<String> result = new HashSet<>();
        result.add(path);
        result.add("*");
        String subpath = path;
        int index;
        while ((index = subpath.lastIndexOf("/")) != -1) {
            subpath = subpath.substring(0, index);
            result.add(subpath + "/*");
        }
        return result;
    }

    private ChildEventListener blessingListener = new ChildEventListener() {
        @Override
        public void onChildAdded(DataSnapshot snapshot, String s) {
            Blessing receivedBlessing = Blessing.fromSnapshot(PermissionManager.this, snapshot);
            receivedBlessing.addListener(blessingChangedListner);
        }

        @Override
        public void onChildChanged(DataSnapshot dataSnapshot, String s) {
        }

        @Override
        public void onChildRemoved(DataSnapshot dataSnapshot) {
            Blessing removedBlessing = mBlessings.remove(dataSnapshot.getKey());
            if (removedBlessing != null) {
                removedBlessing.removeListener(blessingChangedListner);
                mBlessingsTable.remove(removedBlessing.getSource(), removedBlessing.getTarget());
                refreshPermissions();
            }
        }

        @Override
        public void onChildMoved(DataSnapshot dataSnapshot, String s) {

        }

        @Override
        public void onCancelled(DatabaseError databaseError) {

        }
    };

    private Blessing.OnBlessingUpdatedListener blessingChangedListner = new Blessing.OnBlessingUpdatedListener() {
        @Override
        public void onBlessingUpdated(Blessing blessing) {
            refreshPermissions();
        }

        @Override
        public void onBlessingRemoved(Blessing blessing) {
            refreshPermissions();
        }
    };


    public int getPermissions(String path) {
        return mPermissionTree.getPermissions(path);
    }

    public OnPermissionChangeListener addPermissionEventListener(String path, OnPermissionChangeListener listener) {
        int current = FLAG_DEFAULT;
        mPermissionValueEventListeners.put(path, listener);

        String nearestAncestor = Utils.getNearestCommonAncestor(path, mPermissionTree.keySet());
        if (nearestAncestor != null) {
            current = getPermissions(nearestAncestor);
            mNearestAncestors.put(nearestAncestor, path);
        }
        listener.onPermissionChange(current);
        return listener;
    }

    public void removePermissionEventListener(String path, OnPermissionChangeListener listener) {
        mPermissionValueEventListeners.remove(path, listener);
        String nca = Utils.getNearestCommonAncestor(path, mPermissionTree.keySet());
        mNearestAncestors.remove(nca, path);

    }


    public void removeOnRequestListener(String path, OnRequestListener requestListener) {
        mRequestListeners.remove(path, requestListener);
        if (mRequestListeners.values().contains(requestListener)) {
            //TODO: this doesn't catch cases where one request listener unsubscribed
            for (Map.Entry<String, OnRequestListener> entry : mSubscribedRequests.entries()) {
                if (entry.getValue().equals(requestListener)) {
                    String rId = entry.getKey();
                    PermissionRequest request = mRequests.get(rId);
                    if (getAllPaths(request.getPath()).contains(path)) {
                        mSubscribedRequests.remove(rId, requestListener);
                    }
                }
            }

        } else {
            mSubscribedRequests.values().remove(requestListener);
        }
    }

    public OnRequestListener addOnRequestListener(String path, OnRequestListener requestListener) {
        mRequestListeners.put(path, requestListener);
        for (Map.Entry<String, PermissionRequest> entry : mRequests.entrySet()) {
            String rId = entry.getKey();
            PermissionRequest request = entry.getValue();
            Set<String> requestPaths = getAllPaths(request.getPath());
            if (requestPaths.contains(path)) {
                String source = request.getSource();
                if (requestListener.onRequest(request, bless(source))) {
                    mSubscribedRequests.put(rId, requestListener);
                }
            }
        }
        return requestListener;
    }

    public PermissionRequest.Builder request(String path, String group) {
        PermissionRequest.Builder builder = mActiveRequests.get(group, path);
        if (builder == null) {
            builder = new PermissionRequest.Builder(mRequestsRef.push(), path, mId);
            mActiveRequests.put(group, path, builder);
        }
        return builder;
    }

    public void cancelRequests(String group) {
        Collection<PermissionRequest.Builder> builders = mActiveRequests.row(group).values();
        for (PermissionRequest.Builder builder : builders) {
            builder.cancel();
        }
        builders.clear();
    }

    public void cancelRequest(String group, String path) {
        PermissionRequest.Builder builder = mActiveRequests.remove(group, path);
        if (builder != null) {
            builder.cancel();
        }
    }

    public void onDestroy() {
        mBlessingsRef.removeEventListener(blessingListener);
        mRequestsRef.removeEventListener(requestListener);
        for (Blessing blessing : new HashSet<Blessing>(mBlessings.values())) {
            blessing.revoke();
        }
    }

    public interface OnRequestListener {
        boolean onRequest(PermissionRequest request, Blessing blessing);

        void onRequestRemoved(PermissionRequest request, Blessing blessing);
    }

    public interface OnPermissionChangeListener {
        void onPermissionChange(int current);

        void onCancelled(DatabaseError databaseError);
    }
}
