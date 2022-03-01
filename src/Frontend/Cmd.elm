module Frontend.Cmd exposing (setInitialEditorContent, setupWindow)

import Browser.Dom as Dom
import Process
import Task
import Types exposing (FrontendMsg(..))


setupWindow : Cmd FrontendMsg
setupWindow =
    Task.perform GotViewport Dom.getViewport


setInitialEditorContent : Float -> Cmd FrontendMsg
setInitialEditorContent delay =
    Process.sleep delay |> Task.perform (always SetInitialEditorContent)
