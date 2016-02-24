// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package io.v.baku.hellobaku;

import android.app.Activity;
import android.os.Bundle;
import android.widget.EditText;

import io.v.baku.toolkit.BakuActivityMixin;
import io.v.baku.toolkit.BakuActivityTrait;

public class HelloActivityComposition extends Activity {
    private BakuActivityTrait<HelloActivityComposition> mBaku;

    @Override
    protected void onCreate(final Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_hello);

        mBaku = new BakuActivityMixin<>(this, savedInstanceState);

        // Binds the Syncbase row named "message" to displayTextView
        mBaku.binder().key("message")
                .bindTo(R.id.displayTextView);

        final EditText txtInput = (EditText) findViewById(R.id.inputEditText);
        findViewById(R.id.actionButton).setOnClickListener(bn -> {
            // Writes the text of inputEditText to the Syncbase row named "message"
            mBaku.getSyncbaseTable().put("message", txtInput.getText().toString());

            txtInput.setText("");
        });
    }

    @Override
    protected void onDestroy() {
        mBaku.close();
        super.onDestroy();
    }
}
