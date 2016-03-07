// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package io.v.baku.hellobaku;

import android.os.Bundle;
import android.widget.EditText;
import android.widget.TextView;

import io.v.baku.toolkit.BakuActivity;

public class HelloActivity extends BakuActivity {
    @Override
    protected void onCreate(final Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_hello);

        final TextView txtOutput = (TextView) findViewById(R.id.displayTextView);
        // Binds the Syncbase row named "message" to displayTextView, a.k.a. txtOutput.
        binder().onKey("message")
                .bindTo(txtOutput);

        final EditText txtInput = (EditText) findViewById(R.id.inputEditText);
        findViewById(R.id.actionButton).setOnClickListener(bn -> {
            // Setting the text on txtOutput will update the "message" Syncbase row via the data
            // binding we established above.
            txtOutput.setText(txtInput.getText());
            txtInput.setText("");
        });
    }
}
