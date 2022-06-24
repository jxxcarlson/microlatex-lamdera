# Collaborative Editing

## Pipeline

1. `FE.Update.inputText`: If number of editors == 1 then
   handle input normally, otherwise proceed as below.
   
2. `FE.Update.handleEditorChange model cursor content`: use 
    cursor and content to create a new OT.Document; compare
    it  with the old OT.Document to create an `editEvent: EditEvent`; 
    then send `PushEditorEvent editEvent` to the backend.
   
3. `BE.NetworkModel.processEvent event model`: process
    the message `PushEditorEvent editEvent` by calling 
   `Backend.NetworkModel.processEvent event model`.  This
    function uses the event to look up the corresponding
    shared document information, in particular the clientId's
    of the active editors. A `ProcessEvent event` 
    message is narrowcast to those clients.
   
4.  `FE.updateFromBackend`, `ProcessEvent event` proceeds 
     as follows.  First, `NetworkModel.updateFromUser`
    is applied to `event` and `model.networkModel` to
    create a new `NetworkModel`; this is used to update
    the `networkModel` field of the app's model.  Next,
    `NetworkModel.getLocalDocument newNetworkModel` is
    used to create a new `OT.Document`; its content is 
    used to create (via `Compiler.DifferentialParser.init`)
    a new `EditRecord` and hence to update the rendered document.
    Finally, if the current user id is different from the 
    user id of the even, the `editCommand` field of the model is 
    updated with the editCommand corresponding to `event`.
    This is done by `OTCommand.toCommand`
    
5.  If there is a change in `model.editCommand`, the 
    command is encoded using `OTCommand.encode`; this
    value is sent to codeMirror to update the current text.



## Frontend messages

```
 | ResetNetworkModel NetworkModel.NetworkModel Document
 | InitializeNetworkModel NetworkModel.NetworkModel
 | ProcessEvent NetworkModel.EditEvent
   -- update editCommand, networkModel, editRecord
```


## ToBackend

```
InitializeNetworkModelsWithDocument doc ->
PushEditorEvent event -> Backend.NetworkModel.processEvent event model
ResetNetworkModelForDocument doc ->
```
## NetworkMonitor

module View.NetworkMonitor

The network monitor is accessed by the Monitor on/off button
in the footer, RHS.  The network monitor gives a readout
of the state of the local network model and provides
the user with a way to issue network commands, e.g., 

```
insert 10 "ABC" -- insert "ABC" at character position 10

delete 10 3     -- delete 3 characters starting at position 10

skip 10 3       -- move the cursor 3 characters forward from
                -- position 10 (NOT WORKING??)

```

## Codemirror

Code that sends information to Codemirror,
in function `View.Editor.view`:

```
(Html.node "codemirror-editor"
                [ HtmlAttr.attribute "text" model.initialText -- send info to codemirror
                , HtmlAttr.attribute "linenumber" (String.fromInt (model.linenumber - 1)) -- send info to codemirror
                , HtmlAttr.attribute "selection" (stringOfBool model.doSync) -- send info to codemirror

                -- , HtmlAttr.attribute "editorevent" (NetworkModel.toString model.editorEvent)
                , HtmlAttr.attribute "editcommand" (OTCommand.toString model.editCommand.counter model.editCommand.command)
                ]
                []
            )
```

Action by Codemirror

Function `attributeChangedCallback(attr, oldVal, newVal)`,
case "editcommand" invokes `editTransaction(editor, editEvent)`:

```
function editTransaction(editor, editEvent) {
    var event = editEvent
    console.log("!!!@@ editTransaction, EVENT", event)

        switch (event.op) {

               case "insert":
                   (editTransactionForInsert(editor, event.cursor, event.strval))
                   break;

               case "movecursor":
                   (editTransactionForMoveCursor(editor, event.cursor, event.intval))
                   break;

               case "delete":
                    (editTransactionForDelete(editor, event.cursor, event.intval))
                    break;

               case "noop":
                    (editTransactionForNoOp(editor, event.cursor))
                     break;
        }
```