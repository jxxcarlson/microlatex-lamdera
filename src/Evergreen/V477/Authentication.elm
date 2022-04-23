module Evergreen.V477.Authentication exposing (..)

import Dict
import Evergreen.V477.Credentials
import Evergreen.V477.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V477.User.User
    , credentials : Evergreen.V477.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
