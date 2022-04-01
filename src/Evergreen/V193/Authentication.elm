module Evergreen.V193.Authentication exposing (..)

import Dict
import Evergreen.V193.Credentials
import Evergreen.V193.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V193.User.User
    , credentials : Evergreen.V193.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
