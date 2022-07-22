module Evergreen.V722.Authentication exposing (..)

import Dict
import Evergreen.V722.Credentials
import Evergreen.V722.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V722.User.User
    , credentials : Evergreen.V722.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
