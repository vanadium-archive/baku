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
import android.text.InputType;
import android.text.TextWatcher;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.EditText;
import android.widget.Toast;

import com.google.common.collect.HashMultimap;
import com.google.common.collect.Multimap;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.ValueEventListener;
import com.joanzapata.iconify.IconDrawable;
import com.joanzapata.iconify.fonts.MaterialIcons;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import examples.baku.io.permissions.Blessing;
import examples.baku.io.permissions.PermissionManager;
import examples.baku.io.permissions.PermissionRequest;
import examples.baku.io.permissions.PermissionService;
import examples.baku.io.permissions.PermissionedTextLayout;
import examples.baku.io.permissions.R;
import examples.baku.io.permissions.discovery.DevicePickerActivity;
import examples.baku.io.permissions.synchronization.SyncText;
import examples.baku.io.permissions.synchronization.SyncTextDiff;

public class ComposeActivity extends AppCompatActivity implements ServiceConnection {

    public final static String EXTRA_MESSAGE_ID = "messageId";
    public final static String EXTRA_MESSAGE_PATH = "messagePath";

    private String mPath;

    private String mOwner;
    private String mDeviceId;
    private String mId;
    private PermissionService mPermissionService;
    private PermissionManager mPermissionManager;
    private DatabaseReference mMessageRef;
    private DatabaseReference mSyncedMessageRef;

    private Blessing mCastBlessing;
    private Blessing mPublicBlessing;

    PermissionedTextLayout mTo;
    PermissionedTextLayout mFrom;
    PermissionedTextLayout mSubject;
    PermissionedTextLayout mMessage;

    Multimap<String, PermissionRequest> mRequests = HashMultimap.create();
    HashMap<String, PermissionedTextLayout> mPermissionedFields = new HashMap<>();
    HashMap<String, Integer> mPermissions = new HashMap<>();
    HashMap<String, SyncText> syncTexts = new HashMap<>();


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_compose);
        Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        toolbar.setTitle("Compose");
        setSupportActionBar(toolbar);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        getSupportActionBar().setDisplayShowHomeEnabled(true);
        toolbar.setTitle("Compose Message");


        FloatingActionButton fab = (FloatingActionButton) findViewById(R.id.fab);
        fab.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                sendMessage();
            }
        });

        mTo = (PermissionedTextLayout) findViewById(R.id.composeTo);

        mFrom = (PermissionedTextLayout) findViewById(R.id.composeFrom);

        mSubject = (PermissionedTextLayout) findViewById(R.id.composeSubject);

        mMessage = (PermissionedTextLayout) findViewById(R.id.composeMessage);
        mMessage.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE);

        bindService(new Intent(this, PermissionService.class), this, Service.BIND_AUTO_CREATE);
    }


    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_compose, menu);
        menu.findItem(R.id.action_cast).setIcon(
                new IconDrawable(this, MaterialIcons.md_cast)
                        .color(Color.WHITE)
                        .actionBarSize());
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

        } else if (id == android.R.id.home) {
            finish();
        }

        return super.onOptionsItemSelected(item);
    }


    void sendMessage() {
        //TODO: PermissionManager.requestDialog()
        mPermissionManager.request(mPath + "/send", mDeviceId)
                .putExtra(PermissionManager.EXTRA_TIMEOUT, "2000")
                .putExtra(PermissionManager.EXTRA_COLOR, "#F00");
        finish();
    }


    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == DevicePickerActivity.REQUEST_DEVICE_ID && data != null && data.hasExtra(DevicePickerActivity.EXTRA_DEVICE_ID)) {
            String targetDevice = data.getStringExtra(DevicePickerActivity.EXTRA_DEVICE_ID);

            if (!mOwner.equals(targetDevice)) {
                //find most appropriate blessing to extend from
                mCastBlessing = mPermissionManager.getBlessing(mOwner, mDeviceId);
                if (mCastBlessing == null) {
                    mCastBlessing = mPermissionManager.getRootBlessing();
                }
                mCastBlessing.bless(targetDevice)
                        .setPermissions(mPath + "/to", PermissionManager.FLAG_READ)
                        .setPermissions(mPath + "/subject", PermissionManager.FLAG_SUGGEST)
                        .setPermissions(mPath + "/message", PermissionManager.FLAG_SUGGEST);
            }

            JSONObject castArgs = new JSONObject();
            try {
                castArgs.put("activity", ComposeActivity.class.getSimpleName());
                castArgs.put(EXTRA_MESSAGE_PATH, mPath);
                mPermissionService.getMessenger().to(targetDevice).emit("cast", castArgs.toString());
                mPermissionService.updateConstellationDevice(targetDevice);
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
            mPermissionManager = mPermissionService.getPermissionManager();
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

            //parse path to get owner
            String[] pathElements = mPath.split("/");
            if (pathElements != null && pathElements.length > 1) {
                mOwner = pathElements[1];
            }

            mMessageRef = mPermissionService.getFirebaseDB().getReference(mPath);
            mSyncedMessageRef = mPermissionService.getFirebaseDB().getReference("documents/" + mOwner + "/emails/syncedMessages/" + mId);
            mPermissionManager.addPermissionEventListener(mPath, messagePermissionListener);
            initField(mTo, "to");
            initField(mFrom, "from");
            initField(mSubject, "subject");
            initField(mMessage, "message");

//            mPublicBlessing = mPermissionManager.bless("public")
//                    .setPermissions(mPath + "/subject", PermissionManager.FLAG_READ);

            mPermissionManager.addOnRequestListener("documents/" + mDeviceId + "/emails/messages/" + mId + "/*", new PermissionManager.OnRequestListener() {
                @Override
                public boolean onRequest(PermissionRequest request, Blessing blessing) {
                    mRequests.put(request.getPath(), request);
                    return true;
                }

                @Override
                public void onRequestRemoved(PermissionRequest request, Blessing blessing) {

                }
            });

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

    void initField(final PermissionedTextLayout edit, final String key) {
        edit.setSyncText(new SyncText(mDeviceId, PermissionManager.FLAG_SUGGEST, mSyncedMessageRef.child(key), mMessageRef.child(key)));
        edit.setPermissionedTextListener(new PermissionedTextLayout.PermissionedTextListener() {
            @Override
            public void onSelected(final SyncTextDiff diff, PermissionedTextLayout text) {
                int current = mPermissionManager.getPermissions(mPath + "/" + key);
                if ((current & PermissionManager.FLAG_WRITE) == PermissionManager.FLAG_WRITE) {
                    mPermissionService.requestDialog(diff.source + "@" + key, "Apply changes from " + diff.source, "be vigilant",
                            new PermissionService.ActionCallback() {
                                @Override
                                public boolean onAction(Intent intent) {
                                    edit.acceptSuggestions(diff.source);
                                    return true;
                                }
                            }, new PermissionService.ActionCallback() {
                                @Override
                                public boolean onAction(Intent intent) {
                                    edit.rejectSuggestions(diff.source);
                                    return true;
                                }
                            });
                }
            }

            @Override
            public void onAction(int action, PermissionedTextLayout text) {
            }
        });

        mPermissionedFields.put(key, edit);
        final String path = "documents/" + mDeviceId + "/emails/messages/" + mId + "/" + key;

        mPermissionManager.addPermissionEventListener(mPath + "/" + key, new PermissionManager.OnPermissionChangeListener() {
            @Override
            public void onPermissionChange(int current) {
                edit.onPermissionChange(current);
            }

            @Override
            public void onCancelled(DatabaseError databaseError) {

            }
        });
    }

    public void unlink() {
        for (PermissionedTextLayout text : mPermissionedFields.values()) {
            text.unlink();
        }
        if (mPermissionService != null) {
            if (mPublicBlessing != null) {
                mPublicBlessing.revokePermissions(mPath);
            }

            //cancel all requests made from this activity
            mPermissionManager.cancelRequests(mDeviceId + mId);
        }
        unbindService(this);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        unlink();
    }
}
