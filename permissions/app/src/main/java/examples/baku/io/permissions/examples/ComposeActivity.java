// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package examples.baku.io.permissions.examples;

import android.Manifest;
import android.app.Service;
import android.content.ComponentName;
import android.content.ContentResolver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.os.IBinder;
import android.provider.ContactsContract;
import android.support.annotation.NonNull;
import android.support.design.widget.FloatingActionButton;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.support.v7.app.AlertDialog;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.text.InputType;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;
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

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import examples.baku.io.permissions.Blessing;
import examples.baku.io.permissions.PermissionManager;
import examples.baku.io.permissions.PermissionRequest;
import examples.baku.io.permissions.PermissionService;
import examples.baku.io.permissions.PermissionedTextLayout;
import examples.baku.io.permissions.R;
import examples.baku.io.permissions.discovery.DeviceData;
import examples.baku.io.permissions.discovery.DevicePickerActivity;
import examples.baku.io.permissions.synchronization.SyncText;
import examples.baku.io.permissions.synchronization.SyncTextDiff;
import examples.baku.io.permissions.util.Utils;

public class ComposeActivity extends AppCompatActivity implements ServiceConnection {

    public final static String EXTRA_MESSAGE_ID = "messageId";
    public final static String EXTRA_MESSAGE_PATH = "messagePath";
    private final static int SELECT_ATTACHMENT = 1232;

    private String mPath;

    private String mOwner;
    private String mDeviceId;
    private String mId;
    private PermissionService mPermissionService;
    private PermissionManager mPermissionManager;
    private DatabaseReference mMessageRef;
    private DatabaseReference mSyncedMessageRef;

    private Blessing mSourceBlessing;
    private Blessing mPublicBlessing;
    private final Set<String> targetDevices = new HashSet<>();


    private String mGroup;
    private String mAttachment;
    private int mAttachmentPermission;
    private RelativeLayout mAttachmentView;
    private TextView mAttachmentText;
    private ImageView mAttachmentIcon;
    private ImageView mAttachmentCast;

    private PermissionedTextLayout mTo;
    private PermissionedTextLayout mFrom;
    private PermissionedTextLayout mSubject;
    private PermissionedTextLayout mMessage;

    private Multimap<String, PermissionRequest> mRequests = HashMultimap.create();
    private HashMap<String, PermissionedTextLayout> mPermissionedFields = new HashMap<>();
    private HashMap<String, Integer> mPermissions = new HashMap<>();
    private HashMap<String, SyncText> syncTexts = new HashMap<>();

    private ArrayAdapter<String> contactAdapter;
    FloatingActionButton mFab;
    private Menu mMenu;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);


        setContentView(R.layout.activity_compose);
        Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        toolbar.setTitle("Compose");
        setSupportActionBar(toolbar);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        getSupportActionBar().setDisplayShowHomeEnabled(true);
        toolbar.setTitle("Compose");


        mFab = (FloatingActionButton) findViewById(R.id.fab);

        mTo = (PermissionedTextLayout) findViewById(R.id.composeTo);


        mFrom = (PermissionedTextLayout) findViewById(R.id.composeFrom);

        mSubject = (PermissionedTextLayout) findViewById(R.id.composeSubject);

        mMessage = (PermissionedTextLayout) findViewById(R.id.composeMessage);
        mMessage.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE);

        mAttachmentView = (RelativeLayout) findViewById(R.id.composeAttachment);
        mAttachmentText = (TextView) findViewById(R.id.composeAttachmentText);
        mAttachmentIcon = (ImageView) findViewById(R.id.composeAttachmentIcon);
        mAttachmentIcon.setImageDrawable(new IconDrawable(this, MaterialIcons.md_attach_file).actionBarSize());
        mAttachmentCast = (ImageView) findViewById(R.id.composeAttachmentCast);
        mAttachmentCast.setImageDrawable(new IconDrawable(this, MaterialIcons.md_cast).actionBarSize());
        mAttachmentCast.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if(mPublicBlessing != null){
                    int current = mPublicBlessing.getPermissions(mPath + "/attachment");
                    if((current & PermissionManager.FLAG_READ) == PermissionManager.FLAG_READ){
                        mPublicBlessing.setPermissions(mPath + "/attachment", current & ~PermissionManager.FLAG_READ);
                        mAttachmentCast.setImageDrawable(new IconDrawable(ComposeActivity.this, MaterialIcons.md_cast).actionBarSize());
                    }else{
                        mPublicBlessing.setPermissions(mPath + "/attachment", current | PermissionManager.FLAG_READ);
                        mAttachmentCast.setImageDrawable(new IconDrawable(ComposeActivity.this, MaterialIcons.md_cancel).color(Color.RED).actionBarSize());
                    }
                }
            }
        });
        mAttachmentCast.setVisibility(View.GONE);

        setGroup("Inbox");  //default
        setAttachment(null, mAttachmentPermission);

        getContactsPermission();

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
        MenuItem deleteItem = menu.findItem(R.id.action_delete);

        MenuItem attachItem = menu.findItem(R.id.action_attach).setIcon(
                new IconDrawable(this, MaterialIcons.md_attach_file)
                        .color(Color.WHITE)
                        .actionBarSize());
        attachItem.setVisible(false);
        if (mOwner == null || !mOwner.equals(mDeviceId)) {
            attachItem.setVisible(false);
            deleteItem.setVisible(false);
        }
        mMenu = menu;
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        if (id == R.id.action_delete) {
            checkAndSendMessage();  //currently send and delete have the same result
        } else if (id == R.id.action_cast) {
            if (mPermissionService != null) {
                Intent requestIntent = new Intent(ComposeActivity.this, DevicePickerActivity.class);
                requestIntent.putExtra(DevicePickerActivity.EXTRA_REQUEST, DevicePickerActivity.REQUEST_DEVICE_ID);
                requestIntent.putExtra(DevicePickerActivity.EXTRA_REQUEST_ARGS, mPath);
                startActivityForResult(requestIntent, DevicePickerActivity.REQUEST_DEVICE_ID);
            }
        } else if (id == R.id.action_attach) {
            pickAttachment();
        } else if (id == android.R.id.home) {
            finish();
        }

        return super.onOptionsItemSelected(item);
    }

    public void getContactsPermission() {
        // Here, thisActivity is the current activity
        if (ContextCompat.checkSelfPermission(this,
                Manifest.permission.READ_CONTACTS)
                != PackageManager.PERMISSION_GRANTED) {

            if (ActivityCompat.shouldShowRequestPermissionRationale(this,
                    Manifest.permission.READ_CONTACTS)) {

            } else {
                ActivityCompat.requestPermissions(this,
                        new String[]{Manifest.permission.READ_CONTACTS},
                        1);
            }
        } else { //already granted
            onContactsPermissionGranted();
        }
    }

    private void setGroup(String group) {
        mGroup = group;
        boolean editable = false;
        if ("Inbox".equals(group)) {
            mFab.setImageDrawable(new IconDrawable(this, MaterialIcons.md_reply).color(Color.WHITE));
            mFab.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    launchAndCreateMessage(ComposeActivity.this, mMessageRef.getParent(), mFrom.getText(), "myself@email.com", "RE: " + mSubject.getText(), "", null, "Drafts");
                }
            });

        } else if ("Drafts".equals(group)) {
            editable = true;
            mFab.setImageDrawable(new IconDrawable(this, MaterialIcons.md_send).color(Color.WHITE));
            if (mOwner == null || !mOwner.equals(mDeviceId)) {
                if (mMenu != null) {
                    mMenu.findItem(R.id.action_delete).setVisible(false);
                }
                mFab.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        Toast.makeText(ComposeActivity.this, "Can't send message from this device", 0).show();
                    }
                });
            } else {
                mFab.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        checkAndSendMessage();
                    }
                });
            }


            if (mMenu != null) {
                mMenu.findItem(R.id.action_attach).setVisible(true);
            }
        } else if ("Sent".equals(group)) {
            mFab.setImageDrawable(new IconDrawable(this, MaterialIcons.md_forward).color(Color.WHITE));
            mFab.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    launchAndCreateMessage(ComposeActivity.this, mMessageRef.getParent(), "", "myself@email.com", "FWD: " + mSubject.getText(), mMessage.getText(), null, "Drafts");
                }
            });
            if (mMenu != null) {
                mMenu.findItem(R.id.action_attach).setVisible(true);
            }
        }

        mTo.setEditable(editable);
        mSubject.setEditable(editable);
        mMessage.setEditable(editable);
    }



    public void setAttachment(final String attachment, final int permission) {
        this.mAttachment = attachment;
        this.mAttachmentPermission = permission;
        if (attachment == null || (permission & PermissionManager.FLAG_READ) != PermissionManager.FLAG_READ) {
            mAttachmentView.setVisibility(View.GONE);
        } else {
            mAttachmentView.setVisibility(View.VISIBLE);
            mAttachmentView.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    Utils.viewAttachment(ComposeActivity.this, attachment);
                }
            });
            mAttachmentText.setText(attachment);

        }
    }

    public static void launchAndCreateMessage(Context context, DatabaseReference messagesRef, String to, String from, String subject, String msg, String attachment, String group) {
        MessageData data = new MessageData(UUID.randomUUID().toString(), to, from, subject, msg, attachment, group);
        messagesRef.child(data.getId()).setValue(data);
        Intent intent = new Intent(context, ComposeActivity.class);
        intent.putExtra(ComposeActivity.EXTRA_MESSAGE_ID, data.getId());
        context.startActivity(intent);
    }

    private void onContactsPermissionGranted() {
        ArrayList<String> emailAddressCollection = new ArrayList<String>();
        ContentResolver cr = getContentResolver();
        Cursor emailCur = cr.query(ContactsContract.CommonDataKinds.Email.CONTENT_URI, null, null, null, null);
        while (emailCur.moveToNext()) {
            String email = emailCur.getString(emailCur.getColumnIndex(ContactsContract.CommonDataKinds.Email.DATA));
            emailAddressCollection.add(email);
        }
        emailCur.close();
        String[] emailAddresses = new String[emailAddressCollection.size()];
        emailAddressCollection.toArray(emailAddresses);
        contactAdapter = new ArrayAdapter<String>(this,
                android.R.layout.simple_dropdown_item_1line, emailAddresses);
        mTo.setAutoCompleteAdapter(contactAdapter);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        //TODO: generalize to other permissions. Not just contacts
        if (grantResults.length > 0
                && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            onContactsPermissionGranted();
        }
    }


    ArrayList<SyncTextDiff> getSuggestions() {
        ArrayList<SyncTextDiff> result = new ArrayList<>();
        result.addAll(mTo.getSuggestions());
        result.addAll(mFrom.getSuggestions());
        result.addAll(mSubject.getSuggestions());
        result.addAll(mMessage.getSuggestions());
        return result;
    }

    void checkAndSendMessage() {
        //TODO: PermissionManager.requestDialog()
        mPermissionManager.request(mPath + "/send", mDeviceId)
                .putExtra(PermissionManager.EXTRA_TIMEOUT, "2000")
                .putExtra(PermissionManager.EXTRA_COLOR, "#F00");

        if (getSuggestions().size() > 0) {
            AlertDialog.Builder builder = new AlertDialog.Builder(this);
            builder.setMessage("Confirm suggestions before sending message");
            builder.setPositiveButton("Confirm", new DialogInterface.OnClickListener() {
                public void onClick(DialogInterface dialog, int id) {
                    sendMessage();
                }
            });
            builder.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
                public void onClick(DialogInterface dialog, int id) {
                    // User cancelled the dialog
                }
            });

            AlertDialog dialog = builder.create();
            dialog.show();
        } else {
            sendMessage();
        }
    }

    public void sendMessage() {
        mMessageRef.child("group").setValue("Sent");
        for (String device : targetDevices) {
            mPermissionService.removeFromConstellation(device);
        }
        finish();
    }

    private void deleteMessage() {


        if ((mPermissionManager.getPermissions(mPath) & PermissionManager.FLAG_WRITE) == PermissionManager.FLAG_WRITE) {
            mMessageRef.removeValue();
        }
        finish();

    }

    private void pickAttachment() {
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
//        Uri uri = Uri.parse(Environment.getExternalStorageDirectory().getPath());
        intent.setType("*/*");
//        intent.setDataAndType(uri, "file/*");
        startActivityForResult(Intent.createChooser(intent, "Choose Attachment"), SELECT_ATTACHMENT);
    }


    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == DevicePickerActivity.REQUEST_DEVICE_ID && data != null && data.hasExtra(DevicePickerActivity.EXTRA_DEVICE_ID)) {
            String targetDevice = data.getStringExtra(DevicePickerActivity.EXTRA_DEVICE_ID);

            if (!mOwner.equals(targetDevice)) {
                //find most appropriate blessing to extend from
                mSourceBlessing = mPermissionManager.getBlessing(mOwner, mDeviceId);
                if (mSourceBlessing == null) {
                    mSourceBlessing = mPermissionManager.getRootBlessing();
                }
                //set default blessings
//                Blessing deviceBlessing = mSourceBlessing.bless(targetDevice)
//                        .setPermissions(mPath + "/to", PermissionManager.FLAG_SUGGEST)
//                        .setPermissions(mPath + "/subject", PermissionManager.FLAG_SUGGEST)
//                        .setPermissions(mPath + "/message", PermissionManager.FLAG_SUGGEST);
                addTargetDevice(targetDevice);
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
        } else if (requestCode == SELECT_ATTACHMENT && resultCode == RESULT_OK) {
            Uri attachmentUri = data.getData();
//            String path = Utils.getRealPathFromURI(this, attachmentUri);
            String path = Utils.getFileName(this, attachmentUri);
//            File f = new File(path);
            Toast.makeText(this, "Attached " + path, 0).show();
            mMessageRef.child("attachment").setValue(path);
        }
    }

    public void addTargetDevice(String id) {
        targetDevices.add(id);
        for (Map.Entry<String, PermissionedTextLayout> entry : mPermissionedFields.entrySet()) {
            PermissionedTextLayout edit = entry.getValue();
            String key = entry.getKey();
            int current = mPublicBlessing.getPermissions(mPath + "/" + key);
            if ((current & PermissionManager.FLAG_SUGGEST) == PermissionManager.FLAG_SUGGEST) {
                edit.setAction(1, new IconDrawable(ComposeActivity.this, MaterialIcons.md_cancel)
                        .color(Color.RED)
                        .actionBarSize(), "Toggle Permission");
            } else {
                edit.setAction(1, new IconDrawable(ComposeActivity.this, MaterialIcons.md_cast)
                        .color(Color.BLACK)
                        .actionBarSize(), "Toggle Permission");
            }
        }
        mAttachmentCast.setVisibility(View.VISIBLE);
    }

    public void removeTargetDevice(String id) {
        targetDevices.remove(id);
        if (targetDevices.size() == 0) {
            for (Map.Entry<String, PermissionedTextLayout> entry : mPermissionedFields.entrySet()) {
                PermissionedTextLayout edit = entry.getValue();
                edit.clearActions();
            }
            mAttachmentCast.setVisibility(View.GONE);
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

            if (mMenu != null && !mOwner.equals(mDeviceId)) {
                mMenu.findItem(R.id.action_attach).setVisible(false);
                mMenu.findItem(R.id.action_delete).setVisible(false);
            }

            mMessageRef = mPermissionService.getFirebaseDB().getReference(mPath);
            mSyncedMessageRef = mPermissionService.getFirebaseDB().getReference("documents/" + mOwner + "/emails/syncedMessages/" + mId);
            mPermissionManager.addPermissionEventListener(mPath, messagePermissionListener);

            mMessageRef.child("group").addValueEventListener(groupListener);

            mMessageRef.child("attachment").addValueEventListener(attachmentListener);
            mPermissionManager.addPermissionEventListener(mPath + "/attachment", attachmentPermissionListner);

            initField(mTo, "to");
            initField(mFrom, "from");
            initField(mSubject, "subject");
            initField(mMessage, "message");

            mPublicBlessing = mPermissionManager.bless("public");
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

            mPermissionService.addDiscoveryListener(new PermissionService.DiscoveryListener() {
                @Override
                public void onChange(Map<String, DeviceData> devices) {

                }

                @Override
                public void onDisassociate(String deviceId) {
                    if (deviceId.equals(mOwner)) {
                        finish();
                    }else{
                        removeTargetDevice(deviceId);
                    }
                }
            });
        }
    }

    PermissionManager.OnPermissionChangeListener attachmentPermissionListner = new PermissionManager.OnPermissionChangeListener() {
        @Override
        public void onPermissionChange(int current) {
            setAttachment(mAttachment, current);
        }

        @Override
        public void onCancelled(DatabaseError databaseError) {

        }
    };


    ValueEventListener groupListener = new ValueEventListener() {
        @Override
        public void onDataChange(DataSnapshot dataSnapshot) {
            if (dataSnapshot.exists()) {
                String newGroup = dataSnapshot.getValue(String.class);
                setGroup(newGroup);
            }
        }

        @Override
        public void onCancelled(DatabaseError databaseError) {

        }
    };

    ValueEventListener attachmentListener = new ValueEventListener() {
        @Override
        public void onDataChange(DataSnapshot dataSnapshot) {
            if (dataSnapshot.exists()) {
                String newAttachment = dataSnapshot.getValue(String.class);
                setAttachment(newAttachment, mAttachmentPermission);
            }
        }

        @Override
        public void onCancelled(DatabaseError databaseError) {

        }
    };

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
                    Intent content = new Intent(ComposeActivity.this, ComposeActivity.class);
                    content.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
                    String name = diff.getSource();
                    if(mPermissionService.getDiscovered().containsKey(name)){
                        name = mPermissionService.getDiscovered().get(diff.source).getName();
                    }
                    mPermissionService.requestDialog(diff.source, "Apply changes from " + name, "be vigilant",
                            new PermissionService.ActionCallback() {
                                @Override
                                public boolean onAction(Intent intent) {
                                    acceptSuggestions(diff.source);
                                    return true;
                                }
                            }, new PermissionService.ActionCallback() {
                                @Override
                                public boolean onAction(Intent intent) {
                                    rejectSuggestions(diff.source);
                                    return true;
                                }
                            }, content);
                }
            }

            @Override
            public void onAction(int action, PermissionedTextLayout text) {
                if (action == 1) {
                    if (mPublicBlessing != null) {
                        int current = mPublicBlessing.getPermissions(mPath + "/" + key);
                        if ((current & PermissionManager.FLAG_SUGGEST) == PermissionManager.FLAG_SUGGEST) {
                            mPublicBlessing.setPermissions(mPath + "/" + key, current & ~PermissionManager.FLAG_SUGGEST);
                            text.setAction(1, new IconDrawable(ComposeActivity.this, MaterialIcons.md_cast)
                                    .color(Color.BLACK)
                                    .actionBarSize(), "Toggle Permission");
                        } else {
                            mPublicBlessing.setPermissions(mPath + "/" + key, current | PermissionManager.FLAG_SUGGEST);
                            text.setAction(1, new IconDrawable(ComposeActivity.this, MaterialIcons.md_cancel)
                                    .color(Color.RED)
                                    .actionBarSize(), "Toggle Permission");
                        }
                    }
                } else if (action == 2) {
                    mPermissionManager.request(mPath + "/to", mDeviceId)
                            .setPermissions(PermissionManager.FLAG_WRITE)
                            .udpate();
                }
            }
        });

        mPermissionedFields.put(key, edit);
        final String path = "documents/" + mDeviceId + "/emails/messages/" + mId + "/" + key;

        mPermissionManager.addPermissionEventListener(mPath + "/" + key, new PermissionManager.OnPermissionChangeListener() {
            @Override
            public void onPermissionChange(int current) {
                edit.onPermissionChange(current);

                //TODO:generalize the following request button
                if ("to".equals(key)) {
                    if (current == PermissionManager.FLAG_READ) {
                        edit.setAction(2, new IconDrawable(ComposeActivity.this, MaterialIcons.md_vpn_key), "Request Permission");
                    } else {
                        edit.removeAction(2);
                    }

                    if ((current & PermissionManager.FLAG_WRITE) == PermissionManager.FLAG_WRITE) {
                        edit.setAutoCompleteAdapter(contactAdapter);
                    } else {
                        edit.setAutoCompleteAdapter(null);
                    }
                }
            }

            @Override
            public void onCancelled(DatabaseError databaseError) {

            }
        });
    }

    public void acceptSuggestions(String src) {
        for (PermissionedTextLayout text : mPermissionedFields.values()) {
            text.acceptSuggestions(src);
        }
    }

    public void rejectSuggestions(String src) {
        for (PermissionedTextLayout text : mPermissionedFields.values()) {
            text.rejectSuggestions(src);
        }
    }

    public void unlink() {
        for (PermissionedTextLayout text : mPermissionedFields.values()) {
            text.unlink();
        }
        mMessageRef.child("attachment").removeEventListener(attachmentListener);
        mMessageRef.child("group").removeEventListener(groupListener);
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
