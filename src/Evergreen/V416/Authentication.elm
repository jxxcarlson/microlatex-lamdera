module Evergreen.V416.Authentication exposing (..)

import Dict
import Evergreen.V416.Credentials
import Evergreen.V416.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V416.User.User
    , credentials : Evergreen.V416.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
