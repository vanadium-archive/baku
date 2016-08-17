// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package examples.baku.io.permissions.examples;

import com.google.firebase.database.ServerValue;

import java.util.Map;

/**
 * Created by phamilton on 6/22/16.
 */
public class MessageData {

    String id;
    String to = "";
    String from = "";
    String subject = "";
    String message = "";
    String group = "Drafts";
    String attachment;
    long timeStamp;

//    Map<String, Map<String, Integer>> shared = new HashMap<>();

    public MessageData() {
    }

    public MessageData(String id, String to, String from, String subject, String message, String attachment, String group) {
        this.id = id;
        this.to = to;
        this.from = from;
        this.subject = subject;
        this.message = message;
        this.attachment = attachment;
        this.group = group;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getTo() {
        return to;
    }

    public void setTo(String to) {
        this.to = to != null ? to : "";
    }

    public String getFrom() {
        return from;
    }

    public void setFrom(String from) {
        this.from = from != null ? from : "";
    }

    public String getSubject() {
        return subject;
    }

    public void setSubject(String subject) {
        this.subject = subject != null ? subject : "";
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message != null ? message : "";
    }

    public String getGroup() {
        return group;
    }

    public void setGroup(String group) {
        this.group = group;
    }

    public String getAttachment() {
        return attachment;
    }

    public void setAttachment(String attachment) {
        this.attachment = attachment;
    }

    public Map<String, String> getTimeStamp() {
        return ServerValue.TIMESTAMP;
    }

    public void setTimeStamp(long timeStamp) {
        this.timeStamp = timeStamp;
    }
}
