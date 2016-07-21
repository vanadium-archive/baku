// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package examples.baku.io.permissions.examples;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import examples.baku.io.permissions.R;
import examples.baku.io.permissions.util.EventFragment;

/**
 * A placeholder fragment containing a simple view.
 */
public class InboxFragment extends EventFragment {

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.inbox_list, container, false);


        return view;
    }


}
