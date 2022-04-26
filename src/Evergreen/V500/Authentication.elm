module Evergreen.V500.Authentication exposing (..)

import Dict
import Evergreen.V500.Credentials
import Evergreen.V500.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V500.User.User
    , credentials : Evergreen.V500.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
