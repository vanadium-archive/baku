// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package io.v.baku.hellobaku;

import android.os.Bundle;

import io.v.baku.toolkit.BakuActivity;

public class HelloActivity extends BakuActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_hello);

        binder().key("text")
                .bindTo(R.id.textView)
                .bindTo(R.id.editText);
    }
}
