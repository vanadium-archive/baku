// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package examples.baku.io.permissions.discovery;

import android.app.Fragment;
import android.content.ComponentName;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.support.v7.app.AppCompatActivity;

import java.util.Map;

import examples.baku.io.permissions.PermissionService;
import examples.baku.io.permissions.R;
import examples.baku.io.permissions.util.EventFragment;

public class DevicePickerActivity extends AppCompatActivity implements EventFragment.EventFragmentListener, ServiceConnection {

    private PermissionService mPermissionService;
    private Map<String, DeviceData> mDevices;
    private DevicePickerActivityFragment mFragment;

    private int requestCode;
    public static final int REQUEST_FOCUS = -1;
    public static final int REQUEST_DEVICE_ID = 2;
    public static final String EXTRA_REQUEST = "requestCode";
    public static final String EXTRA_DEVICE_ID = "requestCode";
    public static final String EXTRA_REQUEST_ARGS = "requestArgs";

    private Intent mIntent;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        sendBroadcast(new Intent(Intent.ACTION_CLOSE_SYSTEM_DIALOGS));  //close notification tray
        setContentView(R.layout.content_device_picker);

        Intent intent = getIntent();
        if(intent != null){
            requestCode = intent.getIntExtra(EXTRA_REQUEST, REQUEST_FOCUS);
        }

        mIntent = getIntent();
        PermissionService.bind(this);
    }

    @Override
    public void onAttachFragment(Fragment fragment) {
        super.onAttachFragment(fragment);
        mFragment = (DevicePickerActivityFragment)fragment;
        mFragment.setDevices(mDevices);
    }

    @Override
    public boolean onFragmentEvent(int action, Bundle args, EventFragment fragment) {
        switch(action){
            case DevicePickerActivityFragment.EVENT_ITEMCLICKED:
                String dId = args.getString(DevicePickerActivityFragment.ARG_DEVICE_ID);
                if(dId != null){
                    if(requestCode == REQUEST_DEVICE_ID){
                        Intent result = new Intent();
                        result.putExtra(EXTRA_DEVICE_ID,dId);
                        if(mIntent != null && mIntent.hasExtra(EXTRA_REQUEST_ARGS))
                        {
                            result.putExtra(EXTRA_REQUEST_ARGS, mIntent.getStringExtra(EXTRA_REQUEST_ARGS));
                        }
                        setResult(0, result);
                    }else{
                        mPermissionService.addToConstellation(dId);
                    }
                    finish();
                    return true;
                }
                break;
        }
        return false;
    }

    @Override
    public void onServiceConnected(ComponentName name, IBinder service) {
        mPermissionService = ((PermissionService.PermissionServiceBinder)service).getInstance();
        mDevices = mPermissionService.getDiscovered();
        if(mFragment != null){
            mFragment.setDevices(mDevices);
        }
        mPermissionService.addDiscoveryListener(new PermissionService.DiscoveryListener() {
            @Override
            public void onChange(Map<String, DeviceData> devices) {
                if(mFragment != null){
                    mFragment.setDevices(mDevices);
                }
            }

            @Override
            public void onDisassociate(String deviceId) {

            }
        });
    }

    @Override
    public void onServiceDisconnected(ComponentName name) {

    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        unbindService(this);
    }
}
