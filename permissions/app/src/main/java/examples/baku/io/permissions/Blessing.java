// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package examples.baku.io.permissions;

import com.google.common.collect.UnmodifiableIterator;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.ValueEventListener;

import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.Map;
import java.util.Queue;
import java.util.Set;
import java.util.Stack;

import examples.baku.io.permissions.util.Utils;

/**
 * Created by phamilton on 7/9/16.
 */
public class Blessing implements Iterable<Blessing.Permission>, ValueEventListener {

    private static final String KEY_PERMISSIONS = "_permissions";
    private static final String KEY_RULES = "rule";

    private PermissionManager permissionManager;

    private String id;
    private String source;
    private String target;
    private DatabaseReference ref;
    private DatabaseReference rulesRef;
    private DataSnapshot snapshot;

    private Blessing parentBlessing;
    private final Map<String, Integer> permissions = new HashMap<>();
    private final PermissionTree permissionTree = new PermissionTree();

    private final Set<OnBlessingUpdatedListener> blessingListeners = new HashSet<>();


    public interface OnBlessingUpdatedListener {
        void onBlessingUpdated(Blessing blessing);

        void onBlessingRemoved(Blessing blessing);
    }

    private Blessing(PermissionManager permissionManager, String id, String source, String target) {
        this.permissionManager = permissionManager;
        if (id == null) {
//            setRef(permissionManager.getBlessingsRef().push());
            //TEMP: use a combination of source and target for debugging
            setRef(permissionManager.getBlessingsRef().child(source + "_" + target));
            id = this.ref.getKey();

        } else {
            setRef(permissionManager.getBlessingsRef().child(id));
        }
        setId(id);
        setSource(source);
        setTarget(target);

    }

    public static Blessing create(PermissionManager permissionManager, String source, String target) {
        return get(permissionManager, null, source, target, true);
    }

    //root blessings have no source blessing and their id is the same as their target
    public static Blessing createRoot(PermissionManager permissionManager, String target) {
        return get(permissionManager, target, null, target, true);
    }

    public static Blessing get(PermissionManager permissionManager, String id, String source, String target, boolean create) {
        Blessing blessing = permissionManager.getBlessing(source, target);
        if (blessing == null && create) {
            blessing = new Blessing(permissionManager, id, source, target);
            permissionManager.putBlessing(blessing);
        }
        return blessing;
    }

    public static Blessing fromSnapshot(PermissionManager permissionManager, DataSnapshot snapshot) {
        String id = snapshot.getKey();
        String target = snapshot.child("target").getValue(String.class);
        String source = null;
        if (snapshot.hasChild("source"))
            source = snapshot.child("source").getValue(String.class);
        return get(permissionManager, id, source, target, true);
    }

    public OnBlessingUpdatedListener addListener(OnBlessingUpdatedListener listener) {
        blessingListeners.add(listener);
        listener.onBlessingUpdated(this);
        return listener;
    }

    public boolean addListeners(Collection<OnBlessingUpdatedListener> listeners) {
        return this.blessingListeners.addAll(listeners);
    }

    public boolean removeListener(OnBlessingUpdatedListener listener) {
        return blessingListeners.remove(listener);
    }

    public boolean removeListeners(Collection<OnBlessingUpdatedListener> listeners) {
        return blessingListeners.removeAll(listeners);
    }

    private final OnBlessingUpdatedListener parentListener = new OnBlessingUpdatedListener() {
        @Override
        public void onBlessingUpdated(Blessing blessing) {
            permissionTree.parentTree = parentBlessing.permissionTree;
            notifyListeners();
        }

        @Override
        public void onBlessingRemoved(Blessing blessing) {
            //revoke self
            revoke();
        }
    };

    public boolean isSynched() {
        return snapshot != null;
    }

    public String getId() {
        return id;
    }

    public String getSource() {
        return source;
    }

    public String getTarget() {
        return target;
    }

    public void setId(String id) {
        this.id = id;
        ref.child("id").setValue(id);
    }

    private void setSource(String source) {
        if (this.source == null && source != null) {
            if (this.id.equals(source)) {
                throw new IllegalArgumentException("Source can't be equal to id: " + this.id);
            }
            this.source = source;
            ref.child("source").setValue(source);
            parentBlessing = permissionManager.getBlessing(source);
            if (parentBlessing == null) { //retrieve, if manager isn't tracking blessing
                permissionManager.getBlessingsRef().child(source).addListenerForSingleValueEvent(new ValueEventListener() {
                    @Override
                    public void onDataChange(DataSnapshot dataSnapshot) {
                        if (dataSnapshot.exists()) {
                            parentBlessing = Blessing.fromSnapshot(permissionManager, dataSnapshot);
                            parentBlessing.addListener(parentListener);
                        } else {  //destroy self if source doesn't exist
                            revoke();
                        }
                    }

                    @Override
                    public void onCancelled(DatabaseError databaseError) {

                    }
                });
            } else {
                permissionTree.parentTree = parentBlessing.permissionTree;
                parentBlessing.addListener(parentListener);
            }
        }
    }

    private void notifyListeners() {
        for (OnBlessingUpdatedListener listener : blessingListeners) {
            listener.onBlessingUpdated(this);
        }
    }

    public void setTarget(String target) {
        this.target = target;
        ref.child("target").setValue(target);
    }

    private void setSnapshot(DataSnapshot snapshot) {
        if (!snapshot.exists()) {
            throw new IllegalArgumentException("empty snapshot");
        }
        this.snapshot = snapshot;
        if (snapshot.hasChild(KEY_RULES)) {
            this.permissionTree.setRoot(new Permission(snapshot.child(KEY_RULES), null, 0));
        } else {
            this.permissionTree.setRoot(new Permission());
        }
    }

    public Blessing setPermissions(String path, int permissions) {
        this.permissions.put(path, permissions);
        getRef(path).setPermission(permissions);
        return this;
    }

    public void setPermissions(Map<String, Integer> permissions) {
        for (Map.Entry<String, Integer> entry : permissions.entrySet()) {
            setPermissions(entry.getKey(), permissions.get(entry.getValue()));
        }
    }

    public Blessing clearPermissions(String path) {
        getRef(path).clearPermission();
        this.permissions.remove(path);
        return this;
    }

    public Blessing revoke() {
        if (parentBlessing != null) {
            parentBlessing.removeListener(parentListener);
        }
        for (OnBlessingUpdatedListener listener : blessingListeners) {
            listener.onBlessingRemoved(this);
        }
        ref.removeEventListener(this);
        rulesRef.removeValue();
        return this;
    }

    //delete all permission above path
    public Blessing revokePermissions(String path) {
        if (path != null) {
            rulesRef.child(path).removeValue();
        } else {
            rulesRef.removeValue();
        }
        return this;
    }

    private PermissionReference getRef(String path) {
        return new PermissionReference(rulesRef, path);
    }

    private void setRef(DatabaseReference ref) {
        this.ref = ref;
        this.rulesRef = ref.child(KEY_RULES);

        ref.addValueEventListener(this);
    }

    @Override
    public void onDataChange(DataSnapshot dataSnapshot) {
        if (dataSnapshot.exists()) {
            setSnapshot(dataSnapshot);
            notifyListeners();
        }
    }

    @Override
    public void onCancelled(DatabaseError databaseError) {
        databaseError.toException().printStackTrace();
    }

    //return a blessing interface for granting/revoking permissions
    public Blessing bless(String target) {
        Blessing result = getBlessing(target);
        if (result == null) {
            if (isDescendantOf(target) || target.equals(this.target)) {
                throw new IllegalArgumentException("Can't bless a target that already exists in the blessing hiearchy.");
            }
            result = Blessing.create(permissionManager, getId(), target);
        }
        return result;
    }

    public Blessing getBlessing(String target) {
        return permissionManager.getBlessing(getId(), target);
    }

    public boolean isDescendantOf(String target) {
        return this.target.equals(target) || parentBlessing != null && parentBlessing.isDescendantOf(target);
    }


    @Override
    public Iterator<Permission> iterator() {
        return isSynched() ? permissionTree.iterator() : null;
    }

    public PermissionTree getPermissionTree() {
        return permissionTree;
    }


    public static class Permission implements Iterable<Permission> {
        String key;
        String path;
        int inherited;
        int permissions;
        final Map<String, Permission> children = new HashMap();


        public Permission() {
        }

        public Permission(DataSnapshot snapshot, String path, int inherited) {
            this.path = path;
            if (path != null) {
                this.key = snapshot.getKey();
            }
            this.inherited = inherited;
            if (snapshot.hasChild(KEY_PERMISSIONS)) {
                this.permissions |= snapshot.child(KEY_PERMISSIONS).getValue(Integer.class);
            }
            for (DataSnapshot child : snapshot.getChildren()) {
                if (child.getKey().startsWith("_")) { //ignore keys with '_' prefix
                    continue;
                }
                String childPath = child.getKey();
                if (path != null) {
                    childPath = path + "/" + childPath;
                }
                children.put(child.getKey(), new Permission(child, childPath, this.permissions | this.inherited));
            }
        }

        public Permission copy() {
            Permission result = new Permission();
            result.key = key;
            result.path = path;
            result.inherited = inherited;
            result.permissions = permissions;
            for (Permission child : children.values()) {
                result.children.put(child.key, child.copy());
            }
            return result;
        }

        public void addPermissions(int permission) {
            this.permissions |= permission;
            for (Permission child : children.values()) {
                child.setInherited(getPermissions());
            }
        }

        public void setInherited(int permission) {
            if (this.inherited != permission) {
                this.inherited = permission;
                propagateInherited();
            }
        }

        public void propagateInherited() {
            for (Permission child : children.values()) {
                child.setInherited(getPermissions());
            }
        }

        public void removePermissions(int permission) {
            this.permissions &= ~(permission);
            propagateInherited();
        }

        public void checkPermissions(int reference) {
            this.permissions &= reference;
            propagateInherited();
        }

        public void checkPermissions(PermissionTree ref) {
            for (Permission permission : this) {
                permission.permissions &= ref.getPermissions(permission.path);
            }
            setInherited(inherited & ref.getPermissions(path));
        }


        public Permission child(String path) {
            int index = path.indexOf("/");
            if (index != -1) {
                return this.children.get(path);
            }
            Permission child = this.children.get(path.substring(0, index));
            if (child != null && path.length() - index > 1) {
                return child.child(path.substring(index));
            }
            return null;
        }

        public int getPermissions() {
            return permissions | inherited;
        }


        @Override
        public Iterator<Permission> iterator() {
            final Stack<Permission> nodeStack = new Stack<>();
            nodeStack.push(this);

            final Stack<String> pathStack = new Stack<>();
            pathStack.push(null); //default rule

            return new UnmodifiableIterator<Permission>() {
                @Override
                public boolean hasNext() {
                    return !nodeStack.isEmpty();
                }

                @Override
                public Permission next() {
                    Permission node = nodeStack.pop();
                    for (final Permission child : node.children.values()) {
                        nodeStack.push(child);
                    }
                    return node;
                }
            };
        }
    }


    public static class PermissionTree implements Iterable<Permission> {
        Permission root;
        final Map<String, Permission> rules = new HashMap<>();
        PermissionTree parentTree;

        public PermissionTree(DataSnapshot snapshot) {
            setRoot(new Permission(snapshot, null, 0));
        }

        public PermissionTree() {
            setRoot(new Permission());
        }

        public void setRoot(Permission root) {
            this.root = root;
            updateRules();
        }

        public void merge(PermissionTree tree) {
            Permission permissionA;
            Permission permissionB = tree.root;
            permissionB.checkPermissions(tree);   //check no permissions exceed parent
            Queue<Permission> permissionQueue = new LinkedList<>();
            permissionQueue.add(permissionB);

            while (!permissionQueue.isEmpty()) {
                permissionB = permissionQueue.remove();
                permissionA = rules.get(permissionB.path);
                permissionA.addPermissions(tree.getPermissions(permissionB.path));
                for (Permission child : permissionB.children.values()) {
                    if (rules.containsKey(child.path)) {
                        permissionQueue.add(child);
                    } else {
                        Permission childCopy = child.copy();
                        childCopy.setInherited(permissionA.getPermissions());
                        permissionA.children.put(childCopy.key, childCopy);
                    }
                }
            }
            updateRules();
        }

        private void updateRules() {
            rules.clear();
            for (Permission permission : root) {
                rules.put(permission.path, permission);
            }
        }

        public Permission get(String path) {
            return rules.get(path);
        }

        public int getPermissions(String path) {
            path = Utils.getNearestCommonAncestor(path, keySet());
            Permission permission = get(path);
            if (permission == null) {
                return 0;
            }
            int result = permission.getPermissions();
            if (parentTree != null) { //validate
                result &= parentTree.getPermissions(path);
            }
            return result;
        }

        public Set<String> keySet() {
            return rules.keySet();
        }

        public Collection<Permission> values() {
            return rules.values();
        }

        @Override
        public Iterator<Permission> iterator() {
            return root.iterator();
        }
    }
}
