module Frontend.Cmd exposing (setInitialEditorContent, setupWindow)

import Duration
import Effect.Browser.Dom
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Process
import Effect.Task
import Types exposing (FrontendMsg(..))


setupWindow : Command FrontendOnly toMsg FrontendMsg
setupWindow =
    Effect.Task.perform GotViewport Effect.Browser.Dom.getViewport


setInitialEditorContent : Float -> Command restriction toMsg FrontendMsg
setInitialEditorContent delay =
    Effect.Process.sleep (delay |> Duration.milliseconds) |> Effect.Task.perform (always SetInitialEditorContent)
