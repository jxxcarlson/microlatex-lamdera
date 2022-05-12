module CollaborativeEditing.Types exposing (DocId, EditEvent, Msg(..), Username)

import CollaborativeEditing.OT as OT


type alias Username =
    String


type alias DocId =
    String


{-|

    EditEvents are deduced from changes in {cursor, content} emitted by the
    text editor.

-}
type alias EditEvent =
    { cursorChange : Int, operations : List OT.Operation }


type Msg
    = Edit ( Username, OT.Operation )
    | ApplyEventToLocalState Username DocId EditEvent
    | SendToServer Username DocId EditEvent
    | ProcessEventAtServer Username DocId EditEvent
    | CENoOp
