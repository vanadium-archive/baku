// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package examples.baku.io.permissions;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.graphics.drawable.Icon;
import android.os.Binder;
import android.os.IBinder;
import android.provider.Settings;
import android.util.Log;
import android.widget.Toast;

import com.google.firebase.database.ChildEventListener;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseException;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.ValueEventListener;
import com.joanzapata.iconify.IconDrawable;
import com.joanzapata.iconify.fonts.MaterialIcons;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Map;
import java.util.UUID;

import examples.baku.io.permissions.discovery.DeviceData;
import examples.baku.io.permissions.discovery.DevicePickerActivity;
import examples.baku.io.permissions.examples.ComposeActivity;
import examples.baku.io.permissions.examples.EmailActivity;
import examples.baku.io.permissions.messenger.Message;
import examples.baku.io.permissions.messenger.Messenger;
import examples.baku.io.permissions.util.Utils;

public class PermissionService extends Service {

    private static final String TAG = PermissionService.class.getSimpleName();

    static void l(String msg) {
        Log.e(TAG, msg);
    }

    private static boolean mRunning;

    public static boolean isRunning() {
        return mRunning;
    }

    static final int FOREGROUND_NOTIFICATION_ID = -3278;

    static final String KEY_BLESSINGS = PermissionManager.KEY_BLESSINGS;

    public static final String EXTRA_COMMAND = "type";
    public static final String EXTRA_REQUEST_ID = "requestId";
    public static final String EXTRA_NOTIFICATION_ID = "notificationId";
    public static final String EXTRA_ACTION_ID = "notificationId";

    public static final String ACTION_SHARE_EVENT = "examples.baku.io.permissions.ShareEvent";

    NotificationManager mNotificationManager;

    FirebaseDatabase mFirebaseDB;
    DatabaseReference mDevicesReference;
    DatabaseReference mRequestsReference;


    DatabaseReference mMessengerReference;
    Messenger mMessenger;

    DatabaseReference mPermissionsReference;
    PermissionManager mPermissionManager;
    Blessing mDeviceBlessing;

    DatabaseReference mLocalDeviceReference;

    private String mDeviceId;

    private int mNotificationCounter = 0;
    private int mActionCounter = 0;

    final private Map<String, DeviceData> mDiscovered = new HashMap<>();
    final private HashSet<String> mConstellation = new HashSet<>();
    final private Map<String, Integer> mConstellationNotifications = new HashMap<>();

    final private HashSet<DiscoveryListener> mDiscoveryListener = new HashSet<>();
    final private Map<String, Integer> mDiscoveredNotifications = new HashMap<>();

    final private Map<String, Integer> mRequestNotifications = new HashMap<>();

    final private Map<String, ActionCallback> mActionListeners = new HashMap<>();


    private Icon shareIcon;
    private Icon zoomIcon;
    private Icon closeIcon;
    private Icon keyIcon;
    private Icon grantIcon;
    private Icon deviceIcon;
    private Icon castIcon;


    public interface ActionCallback {
        boolean onAction(Intent intent);    //return true if action is complete and the notification can be dismissed
    }

    public interface DiscoveryListener {
        void onChange(Map<String, DeviceData> devices);

        void onDisassociate(String deviceId);
    }

    public class PermissionServiceBinder extends Binder {
        public PermissionService getInstance() {
            return PermissionService.this;
        }
    }

    public PermissionService() {
    }

    @Override
    public void onCreate() {
        super.onCreate();


        mDeviceId = Settings.Secure.getString(getApplicationContext().getContentResolver(),
                Settings.Secure.ANDROID_ID);


        mFirebaseDB = FirebaseDatabase.getInstance();
        mDevicesReference = mFirebaseDB.getReference("_devices");
        mRequestsReference = mFirebaseDB.getReference("requests");


        shareIcon = Utils.iconFromDrawable(new IconDrawable(PermissionService.this, MaterialIcons.md_share));
        zoomIcon = Utils.iconFromDrawable(new IconDrawable(PermissionService.this, MaterialIcons.md_zoom_in));
        closeIcon = Utils.iconFromDrawable(new IconDrawable(PermissionService.this, MaterialIcons.md_close));
        keyIcon = Utils.iconFromDrawable(new IconDrawable(PermissionService.this, MaterialIcons.md_vpn_key));
        grantIcon = Utils.iconFromDrawable(new IconDrawable(PermissionService.this, MaterialIcons.md_check));
        deviceIcon = Utils.iconFromDrawable(new IconDrawable(PermissionService.this, MaterialIcons.md_phone_android));
        castIcon = Utils.iconFromDrawable(new IconDrawable(PermissionService.this, MaterialIcons.md_cast));

        mPermissionManager = new PermissionManager(mFirebaseDB.getReference(), mDeviceId);

        mPermissionManager.getRootBlessing().setPermissions("documents/" + mDeviceId, PermissionManager.FLAG_ROOT);

        mPermissionManager.join("public");

        mPermissionManager.addOnRequestListener("*", new PermissionManager.OnRequestListener() {
            @Override
            public boolean onRequest(PermissionRequest request, Blessing blessing) {

                int nId = mNotificationCounter++;
                String sourceName = "unknown device";
                String source = request.getSource();
                if (source != null && mDiscovered.containsKey(source)) {
                    sourceName = mDiscovered.get(source).getName();
                }

                Intent acceptRequestIntent = new Intent(PermissionService.this, PermissionService.class);
                acceptRequestIntent.putExtra(EXTRA_COMMAND, "acceptRequest");
                acceptRequestIntent.putExtra(EXTRA_REQUEST_ID, request.getId());
                acceptRequestIntent.putExtra(EXTRA_NOTIFICATION_ID, nId);
                PendingIntent acceptRequestPendingIntent = PendingIntent.getService(PermissionService.this, mActionCounter++, acceptRequestIntent, PendingIntent.FLAG_CANCEL_CURRENT);

                Intent rejectRequestIntent = new Intent(PermissionService.this, PermissionService.class);
                rejectRequestIntent.putExtra(EXTRA_COMMAND, "rejectRequest");
                rejectRequestIntent.putExtra(EXTRA_REQUEST_ID, request.getId());
                rejectRequestIntent.putExtra(EXTRA_NOTIFICATION_ID, nId);
                PendingIntent rejectRequestPendingIntent = PendingIntent.getService(PermissionService.this, mActionCounter++, rejectRequestIntent, PendingIntent.FLAG_CANCEL_CURRENT);

                mNotificationManager.cancel(nId);


                Notification notification = new Notification.Builder(PermissionService.this)
                        .setSmallIcon(keyIcon)
                        .setContentTitle("Permission requestDialog from " + sourceName)
                        .addAction(new Notification.Action.Builder(grantIcon, "Grant", acceptRequestPendingIntent).build())
//                        .addAction(new Notification.Action.Builder(R.drawable.ic_close_black_24dp, "Reject", rejectRequestPendingIntent).build())
                        .setDeleteIntent(rejectRequestPendingIntent)
                        .setVibrate(new long[]{100})
                        .setPriority(Notification.PRIORITY_MAX)
                        .build();

                Integer previousNotificationId = mRequestNotifications.get(request.getId());
                if (previousNotificationId != null) {
                    mNotificationManager.cancel(previousNotificationId);
                }

                mNotificationManager.notify(nId, notification);
                mRequestNotifications.put(request.getId(), nId);
                return true;
            }

            @Override
            public void onRequestRemoved(PermissionRequest request, Blessing blessing) {
                if (mRequestNotifications.containsKey(request.getId())) {
                    mNotificationManager.cancel(mRequestNotifications.get(request.getId()));
                }
            }
        });

        IntentFilter filter = new IntentFilter();
        filter.addAction(ACTION_SHARE_EVENT);
        registerReceiver(eventReceiver, filter);

        mNotificationManager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        initForegroundNotification();
        registerDevice();
        initMessenger();
        initDiscovery();

        mRunning = true;
    }

    public void requestDialog(String requestId, String title, String subtitle, ActionCallback accept, ActionCallback reject, Intent content) {
        Integer previousNotificationId = mRequestNotifications.get(requestId);
        if (previousNotificationId != null) {
            mNotificationManager.cancel(previousNotificationId);
        }
        String aId = UUID.randomUUID().toString();
        String dId = UUID.randomUUID().toString();
        Notification.Builder builder = new Notification.Builder(PermissionService.this)
                .setSmallIcon(keyIcon)
                .setContentTitle(title)
                .setSubText(subtitle)
                .addAction(createAction(grantIcon, "Accept", aId, accept))
                .setDeleteIntent(createNotificationCallback(dId, reject))
                .setVibrate(new long[]{100})
                .setPriority(Notification.PRIORITY_MAX);

        if (content != null) {
            builder.setContentIntent(PendingIntent.getActivity(this, mActionCounter++, content, PendingIntent.FLAG_CANCEL_CURRENT));
        }

        Notification notification = builder.build();

        int nId = mNotificationCounter++;
        mNotificationManager.notify(nId, notification);
        mRequestNotifications.put(requestId, nId);
        mRequestNotifications.put(aId, nId);
        mRequestNotifications.put(dId, nId);
    }


    public Messenger getMessenger() {
        return mMessenger;
    }


    public void updateConstellationDevice(String dId) {
        if (!mDiscovered.containsKey(dId)) return;

        DeviceData device = mDiscovered.get(dId);
        String title = device.getName();
        String subtitle = device.getId();   //default
        if (device.getStatus() != null && device.getStatus().containsKey("description")) {
            subtitle = device.getStatus().get("description");
        }
        int icon = R.drawable.ic_phone_android_black_24dp;

        Intent dismissIntent = new Intent(this, PermissionService.class);
        dismissIntent.putExtra("type", "dismiss");
        dismissIntent.putExtra("deviceId", dId);
        PendingIntent dismissPending = PendingIntent.getService(this, mActionCounter++, dismissIntent, PendingIntent.FLAG_CANCEL_CURRENT);

        Notification.Builder notificationBuilder = new Notification.Builder(this)
                .setContentTitle(title)
                .setContentText(subtitle)
                .setSmallIcon(deviceIcon)
                .setVibrate(new long[]{100})
                .setPriority(Notification.PRIORITY_MAX)
                .setDeleteIntent(dismissPending);

        //add contextual actions
        if (mLocalDevice != null && mLocalDevice.getStatus().containsKey(ComposeActivity.EXTRA_MESSAGE_PATH)) {
            final String localPath = mLocalDevice.getStatus().get(ComposeActivity.EXTRA_MESSAGE_PATH);
            final String focus = device.getId();
            notificationBuilder.addAction(createAction(castIcon, "Cast Message", "castMessage", new ActionCallback() {
                @Override
                public boolean onAction(Intent intent) {
                    try {
                        JSONObject castArgs = new JSONObject();
                        castArgs.put("activity", ComposeActivity.class.getSimpleName());
                        castArgs.put(ComposeActivity.EXTRA_MESSAGE_PATH, localPath);
                        mMessenger.to(focus).emit("cast", castArgs.toString());
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                    return false;
                }
            }));
        }
        //add contextual actions
        if (device != null && device.getStatus().containsKey(ComposeActivity.EXTRA_MESSAGE_PATH)) {
            String focusPath = device.getStatus().get(ComposeActivity.EXTRA_MESSAGE_PATH);
            Intent emailIntent = new Intent(PermissionService.this, ComposeActivity.class);
            emailIntent.putExtra(ComposeActivity.EXTRA_MESSAGE_PATH, focusPath);
            emailIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
//            notificationBuilder.addAction(new Notification.Action.Builder(castIcon, "Pull Message", PendingIntent.getActivity(this, 0, emailIntent, PendingIntent.FLAG_CANCEL_CURRENT)).build());
            notificationBuilder.setContentIntent(PendingIntent.getActivity(this, 0, emailIntent, PendingIntent.FLAG_CANCEL_CURRENT));
        }

        mConstellation.add(dId);
        Integer notificationId = mConstellationNotifications.get(dId);
        if (notificationId == null) {
            notificationId = mNotificationCounter++;
            mConstellationNotifications.put(dId, notificationId);
        }
        Notification notification = notificationBuilder.build();
        mNotificationManager.notify(notificationId, notification);
    }


    private Notification.Action createAction(Icon icon, String title, String actionId, ActionCallback callback) {
        PendingIntent actionPendingIntent = createNotificationCallback(actionId, callback);
        return new Notification.Action.Builder(icon, title, actionPendingIntent).build();
    }

    private PendingIntent createNotificationCallback(String actionId, ActionCallback callback) {
        mActionListeners.put(actionId, callback);
        Intent actionIntent = new Intent(this, PermissionService.class);
        actionIntent.putExtra(EXTRA_COMMAND, "actionCallback");
        actionIntent.putExtra(EXTRA_ACTION_ID, actionId);
        return PendingIntent.getService(this, mActionCounter++, actionIntent, PendingIntent.FLAG_CANCEL_CURRENT);
    }

    public PermissionManager getPermissionManager() {
        return mPermissionManager;
    }

    public String getDeviceId() {
        return mDeviceId;
    }

    public Map<String, DeviceData> getDiscovered() {
        return mDiscovered;
    }

    public void setStatus(String key, String value) {
        mDevicesReference.child(mDeviceId).child("status").child(key).setValue(value);
    }

    public void clearStatus(String key) {
        mDevicesReference.child(mDeviceId).child("status").child(key).removeValue();
    }

    public FirebaseDatabase getFirebaseDB() {
        return mFirebaseDB;
    }

    @Override
    public IBinder onBind(Intent intent) {
        return new PermissionServiceBinder();
    }

    void initForegroundNotification() {

        Intent contentIntent = new Intent(this, PermissionService.class);
        PendingIntent contentPendingIntent = PendingIntent.getActivity(this, mActionCounter++, contentIntent, PendingIntent.FLAG_CANCEL_CURRENT);

        Intent discoverIntent = new Intent(getApplicationContext(), PermissionService.class);
        discoverIntent.putExtra(EXTRA_COMMAND, "discover");
        PendingIntent discoverPendingIntent = PendingIntent.getService(this, mActionCounter++, discoverIntent, PendingIntent.FLAG_UPDATE_CURRENT);

        Intent closeIntent = new Intent(getApplicationContext(), PermissionService.class);
        closeIntent.putExtra(EXTRA_COMMAND, "close");
        PendingIntent closePendingIntent = PendingIntent.getService(this, mActionCounter++, closeIntent, PendingIntent.FLAG_UPDATE_CURRENT);

        Notification notification = new Notification.Builder(this)
                .setContentIntent(contentPendingIntent)
                .setSmallIcon(shareIcon)
                .setContentTitle("Discovery service running")
                .addAction(new Notification.Action.Builder(zoomIcon, "Discover", discoverPendingIntent).build())
                .addAction(new Notification.Action.Builder(closeIcon, "Stop", closePendingIntent).build())
                .build();
        startForeground(FOREGROUND_NOTIFICATION_ID, notification);
    }

    void refreshForegroundNotification(Notification notification) {
        mNotificationManager.notify(FOREGROUND_NOTIFICATION_ID, notification);
    }

    public Blessing getRootBlessing() {
        return mPermissionManager.getRootBlessing();
    }

    public void initMessenger() {
        mMessengerReference = mFirebaseDB.getReference("messages");
        mMessenger = new Messenger(mDeviceId, mMessengerReference);

        mMessenger.on("disassociate", new Messenger.Listener() {
            @Override
            public void call(Message msg, Messenger.Ack callback) {
                removeFromConstellation(msg.getMessage());
            }
        });

        mMessenger.on("cast", new Messenger.Listener() {
            @Override
            public void call(Message msg, Messenger.Ack callback) {
                String args = msg.getMessage();
                if (args != null) {
                    try {
                        JSONObject jsonArgs = new JSONObject(args);
                        if (jsonArgs.has("activity")) {
                            if (ComposeActivity.class.getSimpleName().equals(jsonArgs.getString("activity"))) {
                                String path = jsonArgs.getString(ComposeActivity.EXTRA_MESSAGE_PATH);
                                Intent emailIntent = new Intent(PermissionService.this, ComposeActivity.class);
                                emailIntent.putExtra(ComposeActivity.EXTRA_MESSAGE_PATH, path);
                                emailIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                                startActivity(emailIntent);
                            }
                        }

                        //add cast source to constellation
                        updateConstellationDevice(msg.getSource());
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                }
            }
        });
    }

    public void removeFromConstellation(String deviceId) {
        Integer nId = mConstellationNotifications.remove(deviceId);
        if (nId != null) {
            mNotificationManager.cancel(nId);
        }

        if (!mConstellation.contains(deviceId)) {
            return;
        }
        mConstellation.remove(deviceId);
        //revoke all blessings
        for (Blessing blessing : mPermissionManager.getReceivedBlessings()) {
            Blessing granted = blessing.getBlessing(deviceId);
            if (granted != null) {
                granted.revoke();
            }
        }
        for (DiscoveryListener listener : mDiscoveryListener) {
            listener.onDisassociate(deviceId);
        }
        mMessenger.to(deviceId).emit("disassociate", mDeviceId);
    }

    private final BroadcastReceiver eventReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {

        }
    };

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {

        //TODO: move to a broadcast receiver. StartService intents are not ideal.
        if (intent != null && intent.hasExtra(EXTRA_COMMAND)) {
            String type = intent.getStringExtra(EXTRA_COMMAND);
            l("start command " + type);

            if ("actionCallback".equals(type)) {
                if (intent.hasExtra(EXTRA_ACTION_ID)) {
                    String aId = intent.getStringExtra(EXTRA_ACTION_ID);
                    if (mActionListeners.containsKey(aId)) {
                        boolean result = mActionListeners.get(aId).onAction(intent);
                        if (result) {
                            Integer nId = mRequestNotifications.get(aId);
                            if (nId != null) {
                                mNotificationManager.cancel(nId);
                            }
                        }
                    }
                }

            } else if ("discover".equals(type)) {
                if (mDiscovered != null) {

                    Intent discoveryIntent = new Intent(this, DevicePickerActivity.class);
                    discoveryIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    startActivity(discoveryIntent);
                }
            } else if ("acceptRequest".equals(type)) {
                if (intent.hasExtra(EXTRA_REQUEST_ID)) {
                    String rId = intent.getStringExtra(EXTRA_REQUEST_ID);
                    PermissionRequest request = mPermissionManager.getRequest(rId);
                    if (request != null) {
                        mPermissionManager.grantRequest(request);
                    } else {
                        Toast.makeText(getApplicationContext(), "Expired requestDialog", 0).show();
                    }
                }
                if (intent.hasExtra(EXTRA_NOTIFICATION_ID)) {
                    mNotificationManager.cancel(intent.getIntExtra(EXTRA_NOTIFICATION_ID, -1));
                }
            } else if ("rejectRequest".equals(type)) {
                if (intent.hasExtra(EXTRA_REQUEST_ID)) {
                    String rId = intent.getStringExtra(EXTRA_REQUEST_ID);
                    mPermissionManager.finishRequest(rId);
                }

            } else if ("dismiss".equals(type)) {
                String dId = intent.getStringExtra("deviceId");
                if (dId != null) {
                    removeFromConstellation(dId);
                }

            } else if ("clipboardEvent".equals(type)) {

            } else if ("close".equals(type)) {
                stopSelf();
            }
        }
        return super.onStartCommand(intent, flags, startId);
    }

    void registerDevice() {

        mLocalDeviceReference = mDevicesReference.child(mDeviceId);
        mLocalDeviceReference.addValueEventListener(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {
                if (!dataSnapshot.exists()) {
                    resetLocalDevice();
                } else {
                    try {
                        mLocalDevice = dataSnapshot.getValue(DeviceData.class);

                    } catch (DatabaseException e) {
                        e.printStackTrace();
                    }
                }
            }

            @Override
            public void onCancelled(DatabaseError databaseError) {

            }
        });


    }

    private DeviceData mLocalDevice;

    void resetLocalDevice() {
        final String deviceName = android.os.Build.MODEL;
        mLocalDevice = new DeviceData(mDeviceId, deviceName);
        mLocalDevice.setActive(true);
        mLocalDeviceReference.setValue(mLocalDevice);
    }

    void initDiscovery() {
        mDevicesReference.addChildEventListener(new ChildEventListener() {
            @Override
            public void onChildAdded(DataSnapshot dataSnapshot, String s) {
                updateDevice(dataSnapshot);
            }

            @Override
            public void onChildChanged(DataSnapshot dataSnapshot, String s) {
                updateDevice(dataSnapshot);
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
        });
    }

    public void addDiscoveryListener(DiscoveryListener listener) {
        mDiscoveryListener.add(listener);
    }

    private void updateDevice(DataSnapshot dataSnapshot) {
        if (dataSnapshot.exists()) {
            String key = dataSnapshot.getKey();
            if (!mDeviceId.equals(key)) {
                try {
                    DeviceData device = dataSnapshot.getValue(DeviceData.class);
                    if (device != null) {
                        mDiscovered.put(key, device);
                        for (DiscoveryListener listener : mDiscoveryListener) {
                            listener.onChange(mDiscovered);
                        }
                        if (mConstellation.contains(key)) {
                            updateConstellationDevice(key);
                        }
                    }
                } catch (DatabaseException e) {
                    e.printStackTrace();
                }
            }
        }
    }


    @Override
    public void onDestroy() {
        //TODO: clean up firebase listeners in permission manager.
        if (mPermissionManager != null) {
            mPermissionManager.onDestroy();
        }
        unregisterReceiver(eventReceiver);
        super.onDestroy();
    }

    public static void start(Context context) {
        context.startService(new Intent(context, PermissionService.class));
    }

    //convenience class for when context implements ServiceConnection
    //throws cast exception
    public static void bind(Context context) {
        ServiceConnection connection = (ServiceConnection) context;
        bind(context, connection);
    }

    public static void bind(Context context, ServiceConnection connection) {
        context.bindService(new Intent(context, PermissionService.class), connection, BIND_AUTO_CREATE);
    }
}
