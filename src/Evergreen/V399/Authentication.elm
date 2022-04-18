module Evergreen.V399.Authentication exposing (..)

import Dict
import Evergreen.V399.Credentials
import Evergreen.V399.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V399.User.User
    , credentials : Evergreen.V399.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
