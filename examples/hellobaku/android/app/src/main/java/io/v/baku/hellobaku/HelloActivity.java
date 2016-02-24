// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package io.v.baku.hellobaku;

import android.os.Bundle;
import android.widget.EditText;

import io.v.baku.toolkit.BakuActivity;

public class HelloActivity extends BakuActivity {
    @Override
    protected void onCreate(final Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_hello);

        // Binds the Syncbase row named "message" to displayTextView
        binder().key("message")
                .bindTo(R.id.displayTextView);

        final EditText txtInput = (EditText) findViewById(R.id.inputEditText);
        findViewById(R.id.actionButton).setOnClickListener(bn -> {
            // Writes the text of inputEditText to the Syncbase row named "message"
            getSyncbaseTable().put("message", txtInput.getText().toString());

            txtInput.setText("");
        });
    }
}
