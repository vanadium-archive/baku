// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package examples.baku.io.permissions.discovery;

import android.os.Bundle;
import android.support.v7.widget.CardView;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import examples.baku.io.permissions.R;
import examples.baku.io.permissions.util.EventFragment;

/**
 * A placeholder fragment containing a simple view.
 */
public class DevicePickerActivityFragment extends EventFragment {

    public static final int EVENT_ITEMCLICKED = 2;

    public static final String ARG_DEVICE_ID = "deviceId";

    LinkedHashMap<String,DeviceData> devices = new LinkedHashMap<>();
    DeviceListAdapter mAdapter;
    RecyclerView mDeviceRecycler;
    LinearLayoutManager mLayoutManager;


    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_device_picker, container, false);
        mAdapter = new DeviceListAdapter();
        mLayoutManager = new LinearLayoutManager(getActivity());
        mDeviceRecycler = (RecyclerView) view.findViewById(R.id.deviceRecyclerView);
        mDeviceRecycler.setLayoutManager(mLayoutManager);
        mDeviceRecycler.setAdapter(mAdapter);
        return view;
    }

    public void setDevices(Map<String,DeviceData> devices){
        if(devices != null){
            this.devices = new LinkedHashMap<>(devices);
        }else{
            this.devices.clear();
        }
        if(mAdapter != null){
            this.mAdapter.notifyDataSetChanged();
        }
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        public CardView mCardView;
        public ViewHolder(CardView v) {
            super(v);
            mCardView = v;

            mCardView.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {

                }
            });
        }
    }

    class DeviceListAdapter extends RecyclerView.Adapter<ViewHolder> {

        public DeviceData getItem(int position) {
            List<String> order = new ArrayList<>(devices.keySet());
            return devices.get(order.get(position));
        }

        @Override
        public ViewHolder onCreateViewHolder(ViewGroup parent,
                                             int viewType) {
            // create a new view
            CardView v = (CardView) LayoutInflater.from(parent.getContext())
                    .inflate(R.layout.device_card_item, parent, false);
            // set the view's size, margins, paddings and layout parameters
            ViewHolder vh = new ViewHolder(v);
            return vh;
        }

        @Override
        public void onBindViewHolder(ViewHolder holder, int position) {

            final DeviceData item = getItem(position);

            String title = item.getName();
            if (title != null) {
                TextView titleView = (TextView) holder.mCardView.findViewById(R.id.card_title);
                titleView.setText(title);
            }

            holder.mCardView.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    Bundle args = new Bundle();
                    args.putString(ARG_DEVICE_ID, item.getId());
                    onEvent(EVENT_ITEMCLICKED, args);
//                    Intent intent = new Intent(EmailActivity.this, ComposeActivity.class);
//                    intent.putExtra(ComposeActivity.EXTRA_MESSAGE_ID, item.getId());
//                    startActivityForResult(intent, 0);
                }
            });

        }

        @Override
        public int getItemCount() {
            return devices.size();
        }
    }

}
