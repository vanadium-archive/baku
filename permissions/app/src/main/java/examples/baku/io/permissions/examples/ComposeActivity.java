// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package examples.baku.io.permissions.examples;

import android.app.Service;
import android.content.ComponentName;
import android.content.Intent;
import android.content.ServiceConnection;
import android.graphics.Color;
import android.os.Bundle;
import android.os.IBinder;
import android.support.design.widget.FloatingActionButton;
import android.support.design.widget.TextInputLayout;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.EditText;
import android.widget.Toast;

import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.ValueEventListener;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import examples.baku.io.permissions.PermissionManager;
import examples.baku.io.permissions.discovery.DeviceData;
import examples.baku.io.permissions.PermissionService;
import examples.baku.io.permissions.R;
import examples.baku.io.permissions.discovery.DevicePickerActivity;
import examples.baku.io.permissions.synchronization.SyncText;

public class ComposeActivity extends AppCompatActivity implements ServiceConnection {

    public final static String EXTRA_MESSAGE_ID = "messageId";
    public final static String EXTRA_MESSAGE_PATH = "messagePath";

    private String mPath;

    private String mOwner;
    private String mDeviceId;
    private String mId;
    private PermissionService mPermissionService;
    private DatabaseReference mMessageRef;
    private DatabaseReference mSyncedMessageRef;

    String sourceId;


    EditText mToText;
    EditText mFrom;
    EditText mSubject;
    EditText mMessage;

    TextInputLayout mToLayout;
    TextInputLayout mFromLayout;
    TextInputLayout mSubjectLayout;
    TextInputLayout mMessageLayout;


    Map<String, Integer> permissions = new HashMap<>();

    HashMap<String, SyncText> syncTexts = new HashMap<>();

    HashMap<String, ValueEventListener> listeners = new HashMap<>();
    HashMap<String, DataSnapshot> mSnapshots = new HashMap<>();
    DataSnapshot currentSnapshot;

    String original;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_compose);
        Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        toolbar.setTitle("Compose Message");


        FloatingActionButton fab = (FloatingActionButton) findViewById(R.id.fab);
        fab.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                sendMessage();
            }
        });


        mToText = (EditText) findViewById(R.id.composeTo);
        mToLayout = (TextInputLayout) findViewById(R.id.composeToLayout);

        mFrom = (EditText) findViewById(R.id.composeFrom);
        mFromLayout = (TextInputLayout) findViewById(R.id.composeFromLayout);

        mSubject = (EditText) findViewById(R.id.composeSubject);
        mSubjectLayout = (TextInputLayout) findViewById(R.id.composeSubjectLayout);

        mMessage = (EditText) findViewById(R.id.composeMessage);
        mMessageLayout = (TextInputLayout) findViewById(R.id.composeMessageLayout);

        bindService(new Intent(this, PermissionService.class), this, Service.BIND_AUTO_CREATE);
    }


    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_compose, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_send) {
            sendMessage();
        } else if (id == R.id.action_cast) {
            if (mPermissionService != null) {
                    Intent requestIntent = new Intent(ComposeActivity.this, DevicePickerActivity.class);
                    requestIntent.putExtra(DevicePickerActivity.EXTRA_REQUEST, DevicePickerActivity.REQUEST_DEVICE_ID);
                    requestIntent.putExtra(DevicePickerActivity.EXTRA_REQUEST_ARGS, mPath);
                    startActivityForResult(requestIntent, DevicePickerActivity.REQUEST_DEVICE_ID);
            }

        } else if (id == R.id.action_settings) {

        }

        return super.onOptionsItemSelected(item);
    }


    void sendMessage() {

        //TODO: PermissionManager.request()

        finish();
    }


    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == DevicePickerActivity.REQUEST_DEVICE_ID && data != null && data.hasExtra(DevicePickerActivity.EXTRA_DEVICE_ID)) {
            String focus = data.getStringExtra(DevicePickerActivity.EXTRA_DEVICE_ID);
            mPermissionService.getPermissionManager().bless(focus)
                    .setPermissions(mPath, PermissionManager.FLAG_READ)
                    .setPermissions(mPath + "/message", PermissionManager.FLAG_WRITE)
                    .setPermissions(mPath + "/subject", PermissionManager.FLAG_WRITE);
            JSONObject castArgs = new JSONObject();
            try {
                castArgs.put("activity", ComposeActivity.class.getSimpleName());
                castArgs.put(EXTRA_MESSAGE_PATH, mPath);
                mPermissionService.getMessenger().to(focus).emit("cast", castArgs.toString());
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
    }


    @Override
    public void onServiceConnected(ComponentName name, IBinder service) {
        PermissionService.PermissionServiceBinder binder = (PermissionService.PermissionServiceBinder) service;
        mPermissionService = binder.getInstance();


        if (mPermissionService != null) {
            mDeviceId = mPermissionService.getDeviceId();

            Intent intent = getIntent();
            if (intent != null) {
                if (intent.hasExtra(EXTRA_MESSAGE_PATH)) {
                    mPath = intent.getStringExtra(EXTRA_MESSAGE_PATH);
                    String[] pathElements = mPath.split("/");
                    mId = pathElements[pathElements.length - 1];
                } else if (intent.hasExtra(EXTRA_MESSAGE_ID)) {
                    mId = intent.getStringExtra(EXTRA_MESSAGE_ID);
                    mPath = EmailActivity.KEY_DOCUMENTS
                            + "/" + mDeviceId
                            + "/" + EmailActivity.KEY_EMAILS
                            + "/" + EmailActivity.KEY_MESSAGES
                            + "/" + mId;
                }
            }

            if (mPath == null) {
                mId = UUID.randomUUID().toString();
                mPath = "documents/" + mDeviceId + "/emails/messages/" + mId;
            }

            mMessageRef = mPermissionService.getFirebaseDB().getReference(mPath);
            mSyncedMessageRef = mMessageRef.child("syncedValues");
            mPermissionService.getPermissionManager().addPermissionEventListener(mPath, messagePermissionListener);
            wrapTextField(mToLayout, "to");
            wrapTextField(mFromLayout, "from");
            wrapTextField(mSubjectLayout, "subject");
            wrapTextField(mMessageLayout, "message");

            mPermissionService.setStatus(EXTRA_MESSAGE_PATH, mPath);

        }
    }

    PermissionManager.OnPermissionChangeListener messagePermissionListener = new PermissionManager.OnPermissionChangeListener() {
        @Override
        public void onPermissionChange(int current) {
            if (current > 0) {
                mMessageRef.child("id").setValue(mId);
            }
        }

        @Override
        public void onCancelled(DatabaseError databaseError) {

        }
    };


    @Override
    public void onServiceDisconnected(ComponentName name) {

    }

    void wrapTextField(final TextInputLayout editContainer, final String key) {
        final EditText edit = editContainer.getEditText();

        mPermissionService.getPermissionManager().addPermissionEventListener(mPath + "/" + key, new PermissionManager.OnPermissionChangeListener() {
            @Override
            public void onPermissionChange(int current) {
                Log.e(key, "::" + current);
                if ((current & PermissionManager.FLAG_WRITE) == PermissionManager.FLAG_WRITE) {
                    edit.setEnabled(true);
                    edit.setOnClickListener(null);
                    edit.setFocusable(true);
                    edit.setBackgroundColor(Color.TRANSPARENT);
                    linkTextField(edit, key);
                } else if ((current & PermissionManager.FLAG_READ) == PermissionManager.FLAG_READ) {
                    edit.setEnabled(false);
                    edit.setOnClickListener(null);
                    edit.setFocusable(false);
                    edit.setBackgroundColor(Color.TRANSPARENT);
                    linkTextField(edit, key);
                } else {
                    unlinkTextField(key);
                    edit.setEnabled(false);
                    edit.setFocusable(false);
                    edit.setBackgroundColor(Color.BLACK);
                }
            }

            @Override
            public void onCancelled(DatabaseError databaseError) {

            }
        });
    }

    void unlinkTextField(String key) {
        if (syncTexts.containsKey(key)) {
            syncTexts.get(key).unlink();
        }
    }

    void linkTextField(final EditText edit, final String key) {
        final SyncText syncText = new SyncText(mSyncedMessageRef.child(key), mMessageRef.child(key));
        syncTexts.put(key, syncText);

        syncText.setOnTextChangeListener(new SyncText.OnTextChangeListener() {
            @Override
            public void onTextChange(final String currentText) {
                final int sel = Math.min(edit.getSelectionStart(), currentText.length());
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        edit.setText(currentText);
                        if (sel > -1) {
                            edit.setSelection(sel);
                        }
                    }
                });
            }
        });

        edit.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                syncText.update(s.toString());
            }

            @Override
            public void afterTextChanged(Editable s) {

            }
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        unlinkTextField("to");
        unlinkTextField("form");
        unlinkTextField("subject");
        unlinkTextField("message");
        if (mPermissionService != null) {
            mPermissionService.revokeAll();
        }
        unbindService(this);
    }
}
