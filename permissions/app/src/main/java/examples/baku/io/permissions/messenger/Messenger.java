// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package examples.baku.io.permissions.messenger;

import android.provider.ContactsContract;
import android.widget.NumberPicker;

import com.google.firebase.database.ChildEventListener;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseException;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.ValueEventListener;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;

/**
 * Created by phamilton on 6/28/16.
 *
 * !!!!!!!!!FOR PROTOTYPING ONLY!!!!!!!
 * Messaging on top of Firebase real-time database.
 * Handles single target messaging only.
 * Stand in for something like socket.io.
 */
public class Messenger implements ChildEventListener {

    static final String KEY_TARGET = "target";

    static final String KEY_GROUPS = "_groups";

    private String mId;
    private DatabaseReference mReference;

    //hacky client side grouping
    private DatabaseReference mGroupsReference;
    private DataSnapshot mGroups;

    final private Map<String, Listener> mListeners = new HashMap<>();
    final private Map<String, Ack> mCallbacks = new HashMap<>();

    public Messenger(String id, DatabaseReference reference) {
        this.mId = id;
        this.mReference = reference;
        this.mReference.orderByChild(KEY_TARGET).equalTo(mId).addChildEventListener(this);

        this.mGroupsReference = mReference.child(KEY_GROUPS);
        this.mGroupsReference.addValueEventListener(groupsListener);
    }

    public Emitter to(final String target){
        return new Emitter() {
            @Override
            public void emit(String event, String msg, Ack callback) {
                if(event == null) throw new IllegalArgumentException("event argument can't be null.");

                Message message = new Message(event, msg);
                message.setSource(mId);

                if(callback != null){
                    mCallbacks.put(message.getId(), callback);
                    message.setCallback(true);
                }

                if(mGroups == null || mGroups.hasChild(target)){
                    message.setTarget(target);
                    mReference.child(message.getId()).setValue(message);
                }else if(mGroups.exists()){
//                        DataSnapshot members = mGroups.child(target);
//                        if(members.exists()){
//                            for(Iterator<DataSnapshot> iterator = members.getChildren().iterator(); iterator.hasNext();){
//                                String subTarget = iterator.next().getKey();
//                                Message childMessage = message.getChildInstance();
//                                childMessage.setTarget(subTarget);
//                                mReference.child(childMessage.getId()).setValue(childMessage);
//                            }
//                        }
                    }
            }
        };
    }

    public void on(String event, Listener listener){
        if(listener == null){//remove current
            off(event);
        }else{
            mListeners.put(event, listener);
        }
    }

    public void off(String event){
        if(mListeners.containsKey(event)){
            mListeners.remove(event);
        }
    }

    public void join(String group){
        mGroupsReference.child(group).child(mId).setValue(0);
    }

    public void leave(String group){
        mGroupsReference.child(group).child(mId).removeValue();
    }

    ValueEventListener groupsListener = new ValueEventListener() {
        @Override
        public void onDataChange(DataSnapshot dataSnapshot) {

        }

        @Override
        public void onCancelled(DatabaseError databaseError) {

        }
    };


    @Override
    public void onChildAdded(DataSnapshot dataSnapshot, String s) {
        Message message = null;
        try{
            message = dataSnapshot.getValue(Message.class);

        }catch(DatabaseException e){
            e.printStackTrace();
        }

        if(message!= null){
            handleMessage(message);
        }

        //remove from database.
        dataSnapshot.getRef().removeValue();
    }

    private boolean handleMessage(final Message message) {
        String event = message.getType();
        if(mListeners.containsKey(event)){
            Ack callback = null;
            if(message.isCallback()){
                //route response to sending messenger
                callback = new Ack() {
                    @Override
                    public void call(String args) {
                        to(message.getSource()).emit(message.getId(), args);
                    }
                };
            }
            mListeners.get(event).call(message, callback);
            return true;

        //assume that none of the event listeners match the uuid of a message
        }else if(mCallbacks.containsKey(event)){
            mCallbacks.get(event).call(message.getMessage());
            mCallbacks.remove(event);
            return true;
        }
        return false;
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
        databaseError.toException().printStackTrace();
    }

    public void disconnect(){
        mReference.removeEventListener(this);
    }

    public abstract class Emitter{
        public void emit(String event, String msg){
            emit(event, msg, null);
        }

        abstract public void emit(String event, String msg, Ack callback);
    }

    public interface Listener{
        void call(Message msg, Ack callback);
    }

    public interface Ack{
        void call(String args);
    }
}
