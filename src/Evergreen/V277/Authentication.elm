module Evergreen.V277.Authentication exposing (..)

import Dict
import Evergreen.V277.Credentials
import Evergreen.V277.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V277.User.User
    , credentials : Evergreen.V277.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
