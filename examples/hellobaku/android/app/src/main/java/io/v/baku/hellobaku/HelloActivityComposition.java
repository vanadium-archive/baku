// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package io.v.baku.hellobaku;

import android.app.Activity;
import android.os.Bundle;
import android.widget.EditText;
import android.widget.TextView;

import io.v.baku.toolkit.BakuActivityMixin;
import io.v.baku.toolkit.BakuActivityTrait;

public class HelloActivityComposition extends Activity {
    private BakuActivityTrait<HelloActivityComposition> mBaku;

    @Override
    protected void onCreate(final Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_hello);

        mBaku = new BakuActivityMixin<>(this, savedInstanceState);

        final TextView txtOutput = (TextView) findViewById(R.id.displayTextView);
        // Binds the Syncbase row named "message" to displayTextView, a.k.a. txtOutput.
        mBaku.binder().onKey("message")
                .bindTo(txtOutput);

        final EditText txtInput = (EditText) findViewById(R.id.inputEditText);
        findViewById(R.id.actionButton).setOnClickListener(bn -> {
            // Setting the text on txtOutput will update the "message" Syncbase row via the data
            // binding we established above.
            txtOutput.setText(txtInput.getText());
            txtInput.setText("");
        });
    }

    @Override
    protected void onDestroy() {
        mBaku.close();
        super.onDestroy();
    }
}
