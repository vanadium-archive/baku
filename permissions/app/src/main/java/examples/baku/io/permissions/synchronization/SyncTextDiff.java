// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package examples.baku.io.permissions.synchronization;

import org.bitbucket.cowwoc.diffmatchpatch.DiffMatchPatch;

import java.util.Objects;

/**
 * Created by phamilton on 8/5/16.
 */
public class SyncTextDiff {

    public final static int DELETE = 0;
    public final static int INSERT = 1;
    public final static int EQUAL = 2;

    public String text;
    public int operation;
    public String source;
    public int permission;

    public SyncTextDiff() {
    }

    public SyncTextDiff(String text, int operation, String source, int permission) {
        this.text = text;
        this.operation = operation;
        this.source = source;
        this.permission = permission;
    }

    public SyncTextDiff(SyncTextDiff other) {
        this.text = other.text;
        this.operation = other.operation;
        this.source = other.source;
        this.permission = other.permission;
    }


    public int getPermission() {
        return permission;
    }

    public void setPermission(int permission) {
        this.permission = permission;
    }

    public String getSource() {
        return source;
    }

    public void setSource(String source) {
        this.source = source;
    }


    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }

    public int getOperation() {
        return operation;
    }

    public void setOperation(int operation) {
        this.operation = operation;
    }

    public int length() {
        return text == null ? 0 : text.length();
    }

    public boolean compatible(SyncTextDiff other) {
        return compatible(other.operation, other.source);
    }

    public boolean compatible(int operation, String source) {
        return operation == this.operation
                && Objects.equals(this.source, source);
    }

    public SyncTextDiff truncate(int start) {
        SyncTextDiff result = new SyncTextDiff();
        result.setSource(source);
        result.setOperation(operation);
        result.setText(text.substring(start));
        setText(text.substring(0, start));
        return result;
    }

    public static SyncTextDiff fromDiff(DiffMatchPatch.Diff diff, String src, String target) {
        SyncTextDiff result = new SyncTextDiff();
        result.setText(diff.text);
        result.setSource(src);
        int op = EQUAL;
        switch (diff.operation) {
            case DELETE:
                op = SyncTextDiff.DELETE;
                break;
            case INSERT:
                op = SyncTextDiff.INSERT;
        }
        result.setOperation(op);
        return result;
    }


}
