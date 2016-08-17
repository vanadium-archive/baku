// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package examples.baku.io.permissions.synchronization;

import android.util.Log;

import com.google.firebase.database.ChildEventListener;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseException;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.GenericTypeIndicator;
import com.google.firebase.database.MutableData;
import com.google.firebase.database.Transaction;
import com.google.firebase.database.ValueEventListener;

import org.bitbucket.cowwoc.diffmatchpatch.DiffMatchPatch;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.ListIterator;
import java.util.UUID;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;

import examples.baku.io.permissions.PermissionManager;

/**
 * Created by phamilton on 6/24/16.
 */
public class SyncText {

    static final String KEY_CURRENT = "current";
    static final String KEY_TEXT = "value";
    static final String KEY_VERSION = "version";
    static final String KEY_PATCHES = "patches";
    static final String KEY_SUBSCRIBERS = "subscribers";
    static final String KEY_DIFFS = "diffs";

    private final GenericTypeIndicator<ArrayList<SyncTextDiff>> diffListType = new GenericTypeIndicator<ArrayList<SyncTextDiff>>() {
    };

    private LinkedList<SyncTextDiff> diffs = new LinkedList<>();
    private int ver;
    private BlockingQueue<SyncTextPatch> mPatchQueue;

    private DiffMatchPatch diffMatchPatch = new DiffMatchPatch();

    private DatabaseReference mSyncRef;
    private DatabaseReference mPatchesRef;
    private DatabaseReference mOutputRef;

    private PatchConsumer mPatchConsumer;

    private OnTextChangeListener mOnTextChangeListener;

    private String mInstanceId;
    private String mLocalSource;
    private int mPermissions;


    public SyncText(String local, int permissions, DatabaseReference reference, DatabaseReference output) {
        if (reference == null) throw new IllegalArgumentException("null reference");

        mLocalSource = local;
        mPermissions = permissions;
        mSyncRef = reference;
        mOutputRef = output;

        mInstanceId = UUID.randomUUID().toString();

        mPatchQueue = new LinkedBlockingQueue<>();
        mPatchConsumer = new PatchConsumer(mPatchQueue);

        new Thread(mPatchConsumer).start();

        link();
    }


    public LinkedList<SyncTextDiff> getDiffs() {
        return diffs;
    }

    public int getPermissions() {
        return mPermissions;
    }

    public void setPermissions(int mPermissions) {
        this.mPermissions = mPermissions;
        if ((mPermissions & PermissionManager.FLAG_WRITE) == PermissionManager.FLAG_WRITE) {
            acceptSuggestions(mLocalSource);
        }
    }

    public static String getFinalText(LinkedList<SyncTextDiff> diffs) {
        String result = "";
        for (SyncTextDiff diff : diffs) {
            if (diff.operation == SyncTextDiff.EQUAL) {
                result += diff.getText();
            }
        }
        return result;
    }

    public void setOnTextChangeListener(OnTextChangeListener onTextChangeListener) {
        this.mOnTextChangeListener = onTextChangeListener;
    }

    public int update(String newText, int ver) {
        if (mPatchesRef == null) {
            throw new RuntimeException("database connection hasn't been initialized");
        }

        LinkedList<DiffMatchPatch.Patch> patches = diffMatchPatch.patchMake(fromDiffs(this.diffs), newText);

        if (patches.size() > 0) {
            String patchString = diffMatchPatch.patchToText(patches);
            SyncTextPatch patch = new SyncTextPatch();
            patch.setVer(ver);
            patch.setPatch(patchString);
            if (mLocalSource != null) {
                patch.setSource(mLocalSource);
            }
            patch.setPermissions(mPermissions);
            mPatchesRef.push().setValue(patch);
            return patch.getVer();
        }
        return -1;
    }

    public int update(String newText) {
        return update(newText, ver + 1);
    }

    private LinkedList<SyncTextDiff> toDiffs(String text) {
        LinkedList<SyncTextDiff> diffs = new LinkedList<>();
        diffs.add(new SyncTextDiff(text, SyncTextDiff.EQUAL, mLocalSource, mPermissions));
        return diffs;
    }

    //TODO: this method currently waits for server confirmation to notify listeners. Ideally, it should notify immediately and revert on failure
    private void updateCurrent(final int ver, final LinkedList<SyncTextDiff> diffs) {
        final String text = getFinalText(diffs);
        this.ver = ver;
        this.diffs = diffs;
        mSyncRef.child(KEY_CURRENT).removeEventListener(mCurrentValueListener);
        mSyncRef.child(KEY_CURRENT).runTransaction(new Transaction.Handler() {
            @Override
            public Transaction.Result doTransaction(MutableData currentData) {
                if (currentData.getValue() == null) {
                    currentData.child(KEY_TEXT).setValue(text);
                    currentData.child(KEY_VERSION).setValue(ver);
                    currentData.child(KEY_DIFFS).setValue(diffs);

                } else {
                    int latest = currentData.child(KEY_VERSION).getValue(Integer.class);
                    if (latest > ver) {
                        return Transaction.abort();
                    }
                    currentData.child(KEY_TEXT).setValue(text);
                    currentData.child(KEY_VERSION).setValue(ver);
                    currentData.child(KEY_DIFFS).setValue(diffs);
                }
                return Transaction.success(currentData);
            }

            @Override
            public void onComplete(DatabaseError databaseError, boolean success, DataSnapshot dataSnapshot) {
                if (success) {
                    notifyListeners(diffs, ver);
                }
                mSyncRef.child(KEY_CURRENT).addValueEventListener(mCurrentValueListener);
            }
        });
    }

    private void notifyListeners(LinkedList<SyncTextDiff> diffs, int ver) {
        String text = getFinalText(diffs);
        if (mOnTextChangeListener != null) {
            mOnTextChangeListener.onTextChange(text, diffs, ver);
        }
        if (mOutputRef != null) {  //pass successful change to output location
            mOutputRef.setValue(text);
        }
    }

    public void link() {

        mSyncRef.child(KEY_SUBSCRIBERS).child(mInstanceId).setValue(0);

        mPatchesRef = mSyncRef.child(KEY_PATCHES);
        if (mOutputRef != null) {
            mOutputRef.addListenerForSingleValueEvent(pullCurrentOutput);
        } else {
            mSyncRef.child(KEY_CURRENT).addListenerForSingleValueEvent(mInitValueListener);
        }
    }

    private ValueEventListener mInitValueListener = new ValueEventListener() {
        @Override
        public void onDataChange(DataSnapshot dataSnapshot) {
            if (dataSnapshot.exists()) {
                if (dataSnapshot.hasChild(KEY_DIFFS)) {
                    diffs = new LinkedList<SyncTextDiff>(dataSnapshot.child(KEY_DIFFS).getValue(diffListType));
                }
                ver = dataSnapshot.child(KEY_VERSION).getValue(Integer.class);
            } else {  //version 0, empty string
                updateCurrent(0, new LinkedList<>(diffs));
            }
            notifyListeners(diffs, ver);

//                mPatchesRef.orderByChild(KEY_VERSION).startAt(ver).addChildEventListener(mPatchListener);
            mPatchesRef.addChildEventListener(mPatchListener);
            mSyncRef.child(KEY_CURRENT).addValueEventListener(mCurrentValueListener);
        }

        @Override
        public void onCancelled(DatabaseError databaseError) {

        }
    };

    private ValueEventListener pullCurrentOutput = new ValueEventListener() {
        @Override
        public void onDataChange(DataSnapshot dataSnapshot) {
            if (dataSnapshot.exists()) {
                String atOutput = dataSnapshot.getValue(String.class);
                if (atOutput != null) {
                    diffs = toDiffs(atOutput);
                }
            }
            mSyncRef.child(KEY_CURRENT).addListenerForSingleValueEvent(mInitValueListener);
        }

        @Override
        public void onCancelled(DatabaseError databaseError) {

        }
    };

    private ValueEventListener mCurrentValueListener = new ValueEventListener() {
        @Override
        public void onDataChange(DataSnapshot dataSnapshot) {
            if (dataSnapshot.exists()) {
                int version = dataSnapshot.child(KEY_VERSION).getValue(Integer.class);
                if (dataSnapshot.hasChild(KEY_DIFFS)) {
                    ver = version;
                    diffs = new LinkedList<SyncTextDiff>(dataSnapshot.child(KEY_DIFFS).getValue(diffListType));
                    notifyListeners(diffs, ver);
                }
            }
        }

        @Override
        public void onCancelled(DatabaseError databaseError) {

        }
    };

    private ChildEventListener mPatchListener = new ChildEventListener() {
        @Override
        public void onChildAdded(DataSnapshot dataSnapshot, String s) {
            try {
                SyncTextPatch patch = dataSnapshot.getValue(SyncTextPatch.class);
                if (patch != null) {
                    mPatchQueue.add(patch);
                }
            } catch (DatabaseException e) {
                e.printStackTrace();
            }

            dataSnapshot.getRef().removeValue();
        }

        @Override
        public void onChildChanged(DataSnapshot dataSnapshot, String s) {

        }

        @Override
        public void onChildRemoved(DataSnapshot dataSnapshot) {

        }

        @Override
        public void onChildMoved(DataSnapshot dataSnapshot, String s) {

        }

        @Override
        public void onCancelled(DatabaseError databaseError) {

        }
    };

    public void unlink() {
        mSyncRef.child(KEY_PATCHES).removeEventListener(mPatchListener);
        mSyncRef.child(KEY_SUBSCRIBERS).child(mInstanceId).removeValue();
    }

    public interface OnTextChangeListener {
        void onTextChange(String finalText, LinkedList<SyncTextDiff> diffs, int ver);
    }

    private class PatchConsumer implements Runnable {
        private final BlockingQueue<SyncTextPatch> queue;

        PatchConsumer(BlockingQueue q) {
            queue = q;
        }

        public void run() {
            try {
                while (true) {
                    consume(queue.take());
                }
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }

        void consume(SyncTextPatch patch) {
            processPatch(patch);
        }
    }

    private static String fromDiffs(List<SyncTextDiff> diffs) {
        String result = "";
        for (SyncTextDiff diff : diffs) {
            result += diff.getText();
        }
        return result;
    }

    boolean hasWrite(SyncTextPatch patch) {
        return (patch.getPermissions() & PermissionManager.FLAG_WRITE) == PermissionManager.FLAG_WRITE;
    }

    //TODO: bug when duplicate letter patterns in the text. The diff algorithm doesn't take source into account.
    //TODO: this method doesn't handle delete operations on diffs with different sources (e.g. deleting another sources suggestion), these operations are currently ignored
    void processPatch(SyncTextPatch patch) {
        int v = patch.getVer();
        if (this.ver >= v) {  //ignore patches for previous versions
            return;
        }

        String previous = fromDiffs(this.diffs);
        String source = patch.getSource();
        LinkedList<DiffMatchPatch.Patch> patches = new LinkedList<>(diffMatchPatch.patchFromText(patch.getPatch()));
        Object[] patchResults = diffMatchPatch.patchApply(patches, previous);

        if (patchResults == null) {   //return if failed to apply patch
            return;
        }

        String patched = (String) patchResults[0];
        LinkedList<DiffMatchPatch.Diff> diffs = diffMatchPatch.diffMain(previous, patched);
        LinkedList<SyncTextDiff> result = new LinkedList<>();
        ListIterator<SyncTextDiff> previousIterator = new LinkedList<>(this.diffs).listIterator();
        SyncTextDiff previousDiff = null;
        SyncTextDiff last = null;

        int length;

        for (DiffMatchPatch.Diff current : diffs) {
            int operation = current.operation.ordinal();
            String value = current.text;

            if (previousDiff == null && previousIterator.hasNext()) {
                previousDiff = previousIterator.next();
            }

            switch (operation) {
                case SyncTextDiff.EQUAL:
                    length = value.length();
                    while (previousDiff.length() <= length) {
                        result.add(previousDiff);
                        length -= previousDiff.length();
                        if (previousIterator.hasNext()) {
                            previousDiff = previousIterator.next();
                        }
                    }
                    if (length > 0) {
                        SyncTextDiff splitDiff = previousDiff.truncate(length);
                        result.add(previousDiff);
                        previousDiff = splitDiff;
                    }
                    break;
                case SyncTextDiff.INSERT:
                    last = result.peekLast();
                    if (last != null && last.compatible(operation, source) && !hasWrite(patch)) {
                        last.text += value;
                    } else if (hasWrite(patch)) {
                        result.add(new SyncTextDiff(current.text, SyncTextDiff.EQUAL, source, patch.getPermissions()));
                    } else {
                        result.add(new SyncTextDiff(current.text, operation, source, patch.getPermissions()));
                    }
                    break;
                case SyncTextDiff.DELETE:
                    length = value.length();
                    while (previousDiff.length() <= length) {
                        if (!hasWrite(patch) && (!source.equals(previousDiff.source) || previousDiff.operation != SyncTextDiff.INSERT)) {
                            previousDiff.setSource(source);
                            previousDiff.setOperation(operation);
                            result.add(previousDiff);
                        }
                        length -= previousDiff.length();
                        if (previousIterator.hasNext()) {
                            previousDiff = previousIterator.next();
                        }
                    }
                    if (length > 0) {
                        if (!hasWrite(patch) && (!source.equals(previousDiff.source) || previousDiff.operation != SyncTextDiff.INSERT)) {
                            SyncTextDiff splitDiff = previousDiff.truncate(length);
                            previousDiff.setSource(source);
                            previousDiff.setOperation(operation);
                            result.add(previousDiff);
                            previousDiff = splitDiff;
                        } else {
                            previousDiff.text = previousDiff.text.substring(0, length);
                        }
                    }
                    break;
            }
        }

        //merge compatible diffs
        reduceDiffs(result);

        updateCurrent(v, result);

    }

    static void reduceDiffs(LinkedList<SyncTextDiff> diffs) {
        if (!diffs.isEmpty()) {
            Iterator<SyncTextDiff> iterator = diffs.iterator();
            SyncTextDiff neighbor = iterator.next();
            while (iterator.hasNext()) {
                SyncTextDiff diff = iterator.next();
                if (neighbor.compatible(diff)) {
                    neighbor.text += diff.text;
                    iterator.remove();
                } else {
                    neighbor = diff;
                }
            }
        }
    }

    public void acceptSuggestions() {
        acceptSuggestions(mLocalSource);
    }

    public void acceptSuggestions(String source) {
        LinkedList<SyncTextDiff> result = new LinkedList<>(diffs);
        boolean change = false;
        for (Iterator<SyncTextDiff> iterator = result.iterator(); iterator.hasNext(); ) {
            SyncTextDiff diff = iterator.next();
            if (diff.source.equals(source)) {
                switch (diff.operation) {
                    case SyncTextDiff.DELETE:
                        iterator.remove();
                        change = true;
                        break;
                    case SyncTextDiff.INSERT:
                        change = true;
                        diff.operation = SyncTextDiff.EQUAL;
                        break;
                }
            }
        }
        if (change) {
            updateCurrent(ver + 1, result);
        }
    }

    public void rejectSuggestions() {
        rejectSuggestions(mLocalSource);
    }

    public void rejectSuggestions(String source) {
        LinkedList<SyncTextDiff> result = new LinkedList<>(diffs);
        for (Iterator<SyncTextDiff> iterator = result.iterator(); iterator.hasNext(); ) {
            SyncTextDiff diff = iterator.next();
            if (diff.source.equals(source)) {
                switch (diff.operation) {
                    case SyncTextDiff.DELETE:
                        diff.operation = SyncTextDiff.EQUAL;
                        break;
                    case SyncTextDiff.INSERT:
                        iterator.remove();
                        break;
                }
            }
        }
        updateCurrent(ver + 1, result);
    }

}
