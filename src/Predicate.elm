module Predicate exposing
    ( documentIsMine
    , documentIsMineOrSharedToMe
    , isSharedToMe
    , isSharedToMe_
    , isShared_
    )

import Document
import User


documentIsMineOrSharedToMe : Maybe Document.Document -> Maybe User.User -> Bool
documentIsMineOrSharedToMe maybeDoc maybeUser =
    documentIsMine maybeDoc maybeUser || isSharedToMe maybeDoc maybeUser


documentIsMine : Maybe Document.Document -> Maybe User.User -> Bool
documentIsMine maybeDoc maybeUser =
    case ( maybeDoc, maybeUser ) of
        ( Nothing, _ ) ->
            False

        ( _, Nothing ) ->
            False

        ( Just doc, Just user ) ->
            doc.author == Just user.username


isSharedToMe : Maybe Document.Document -> Maybe User.User -> Bool
isSharedToMe mUser mDoc =
    case ( mUser, mDoc ) of
        ( Nothing, _ ) ->
            False

        ( _, Nothing ) ->
            False

        ( Just doc, Just user ) ->
            List.member user.username doc.sharedWith.readers || List.member user.username doc.sharedWith.editors


isSharedToMe_ : Maybe String -> Document.Document -> Bool
isSharedToMe_ mUsername doc =
    case mUsername of
        Nothing ->
            False

        Just username ->
            List.member username doc.sharedWith.readers || List.member username doc.sharedWith.editors


isShared_ : Maybe String -> Document.Document -> Bool
isShared_ mUsername doc =
    case mUsername of
        Nothing ->
            False

        Just username ->
            List.member username doc.sharedWith.readers || List.member username doc.sharedWith.editors
