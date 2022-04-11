module Evergreen.V351.Authentication exposing (..)

import Dict
import Evergreen.V351.Credentials
import Evergreen.V351.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V351.User.User
    , credentials : Evergreen.V351.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
