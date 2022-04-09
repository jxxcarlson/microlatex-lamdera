module Authentication exposing
    ( AuthenticationDict
    , UserData
    , encryptForTransit
    , insert
    , updateUser
    , userIdFromUserName
    , userList
    , users
    , verify
    )

import Config
import Credentials exposing (Credentials)
import Crypto.HMAC exposing (sha256)
import Dict exposing (Dict)
import PBKDF2 exposing (Error(..))
import User exposing (User)


type alias Username =
    String


type alias UserData =
    { user : User, credentials : Credentials }


type alias AuthenticationDict =
    Dict Username UserData


userIdFromUserName : String -> AuthenticationDict -> Maybe String
userIdFromUserName username authDict =
    Dict.get username authDict |> Debug.log "(AUTH)" |> Maybe.map (.user >> .id)


updateUser : User -> AuthenticationDict -> AuthenticationDict
updateUser user authDict =
    case Dict.get user.username authDict of
        Nothing ->
            authDict

        Just userData ->
            let
                newUserData =
                    { userData | user = user }
            in
            Dict.insert user.username newUserData authDict


userList : AuthenticationDict -> List User
userList authDict =
    Dict.toList authDict |> List.map (\( _, item ) -> item.user)



-- Dict.update user.username lift (\{user, credentials} -> newUserData authDict


users : AuthenticationDict -> List User
users authDict =
    authDict |> Dict.values |> List.map .user


insert : User -> String -> String -> AuthenticationDict -> Result String AuthenticationDict
insert user salt transitPassword authDict =
    case Credentials.hashPw salt transitPassword of
        Err err ->
            case err of
                DecodingError ->
                    Err "Oops, please press Sign Up again."

                _ ->
                    Err "Unknown error"

        Ok credentials ->
            case Dict.get user.username authDict of
                Nothing ->
                    Ok (Dict.insert user.username { user = user, credentials = credentials } authDict)

                Just _ ->
                    Err "that username is taken"


encryptForTransit : String -> String
encryptForTransit str =
    Crypto.HMAC.digest sha256 Config.transitKey str


verify : String -> String -> AuthenticationDict -> Bool
verify username transitPassword authDict =
    case Dict.get username authDict of
        Nothing ->
            False

        Just data ->
            case Credentials.check transitPassword data.credentials of
                Ok () ->
                    True

                Err _ ->
                    False
