module Predicate exposing
    ( documentIsMine
    , documentIsMineOrIAmAnEditor
    , documentIsMineOrIAmAnEditor_
    , documentIsMineOrSharedToMe
    , isMaster
    , isSharedToMe
    , isSharedToMe_
    , isShared_
    , shouldNarrowcast
    )

import Compiler.ASTTools
import Compiler.DifferentialParser
import Document
import User


shouldNarrowcast : Maybe User.User -> Maybe Document.Document -> Bool
shouldNarrowcast currentUser currentDocument =
    let
        mCurrentUsername : Maybe String
        mCurrentUsername =
            Maybe.map .username currentUser

        currentEditorsOtherThanMe =
            currentDocument
                |> Maybe.map .currentEditorList
                |> Maybe.withDefault []
                |> List.filter (\item -> Just item.username /= mCurrentUsername)
    in
    List.length currentEditorsOtherThanMe > 0


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


documentIsMineOrIAmAnEditor : Maybe Document.Document -> Maybe User.User -> Bool
documentIsMineOrIAmAnEditor mDoc mUser =
    documentIsMine mDoc mUser || iAmAnEditor mDoc mUser


documentIsMineOrIAmAnEditor_ : Document.Document -> Maybe User.User -> Bool
documentIsMineOrIAmAnEditor_ doc mUser =
    documentIsMine (Just doc) mUser || iAmAnEditor (Just doc) mUser


iAmAnEditor : Maybe Document.Document -> Maybe User.User -> Bool
iAmAnEditor mDoc mUser =
    case ( mUser, mDoc ) of
        ( Nothing, _ ) ->
            False

        ( _, Nothing ) ->
            False

        ( Just user, Just doc ) ->
            List.member user.username doc.sharedWith.editors


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


isMaster : Compiler.DifferentialParser.EditRecord -> Bool
isMaster editRecord =
    Compiler.ASTTools.existsBlockWithName editRecord.parsed "collection"
