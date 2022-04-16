module Evergreen.V390.Authentication exposing (..)

import Dict
import Evergreen.V390.Credentials
import Evergreen.V390.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V390.User.User
    , credentials : Evergreen.V390.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
