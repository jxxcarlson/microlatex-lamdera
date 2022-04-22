module Predicate exposing
    ( documentIsMine
    , isSharedToMe
    , isSharedToMe_
    , isShared_
    )

import Document
import User


documentIsMine : Maybe Document.Document -> Maybe User.User -> Bool
documentIsMine maybeDoc maybeUser =
    case ( maybeDoc, maybeUser ) of
        ( Nothing, _ ) ->
            False

        ( _, Nothing ) ->
            False

        ( Just doc, Just user ) ->
            doc.author == Just user.username


isSharedToMe : Maybe User.User -> Document.Document -> Bool
isSharedToMe mUser doc =
    case mUser of
        Nothing ->
            False

        Just user ->
            case doc.share of
                Document.NotShared ->
                    False

                Document.ShareWith { readers, editors } ->
                    List.member user.username readers || List.member user.username editors


isSharedToMe_ : Maybe String -> Document.Document -> Bool
isSharedToMe_ mUsername doc =
    case mUsername of
        Nothing ->
            False

        Just username ->
            case doc.share of
                Document.NotShared ->
                    False

                Document.ShareWith { readers, editors } ->
                    List.member username readers || List.member username editors


isShared_ : Maybe String -> Document.Document -> Bool
isShared_ mUsername doc =
    case mUsername of
        Nothing ->
            False

        Just username ->
            case doc.share of
                Document.NotShared ->
                    False

                Document.ShareWith { readers, editors } ->
                    List.isEmpty readers && List.isEmpty editors |> not
