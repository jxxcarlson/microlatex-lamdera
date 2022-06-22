# Collaborative Editing


## Frontend

```
 | ResetNetworkModel NetworkModel.NetworkModel Document
 | InitializeNetworkModel NetworkModel.NetworkModel
 | ProcessEvent NetworkModel.EditEvent
   -- update editCommand, networkModel, editRecord
```


## Backend

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