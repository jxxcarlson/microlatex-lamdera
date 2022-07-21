module Frontend.Widget exposing (toggleExtrasSidebar, toggleSidebar)

import Effect.Command
import Effect.Lamdera
import Message
import Types
    exposing
        ( MessageStatus(..)
        , SidebarExtrasState(..)
        , SidebarTagsState(..)
        , ToBackend(..)
        )
import User


toggleExtrasSidebar model =
    case model.sidebarExtrasState of
        SidebarExtrasIn ->
            ( { model | sidebarExtrasState = SidebarExtrasOut, sidebarTagsState = SidebarTagsIn }
            , Effect.Lamdera.sendToBackend GetUsersWithOnlineStatus
            )

        SidebarExtrasOut ->
            ( { model | sidebarExtrasState = SidebarExtrasIn }, Effect.Command.none )


toggleSidebar model =
    let
        tagSelection =
            model.tagSelection
    in
    case model.sidebarTagsState of
        SidebarTagsIn ->
            ( { model | sidebarExtrasState = SidebarExtrasIn, sidebarTagsState = SidebarTagsOut }
            , Effect.Command.batch
                [ Effect.Lamdera.sendToBackend GetPublicTagsFromBE
                , Effect.Lamdera.sendToBackend (GetUserTagsFromBE (User.currentUsername model.currentUser))
                ]
            )

        SidebarTagsOut ->
            ( { model | messages = Message.make "Tags in" MSYellow, tagSelection = tagSelection, sidebarTagsState = SidebarTagsIn }, Effect.Command.none )
