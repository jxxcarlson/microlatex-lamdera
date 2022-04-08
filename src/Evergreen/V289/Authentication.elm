module Evergreen.V289.Authentication exposing (..)

import Dict
import Evergreen.V289.Credentials
import Evergreen.V289.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V289.User.User
    , credentials : Evergreen.V289.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
