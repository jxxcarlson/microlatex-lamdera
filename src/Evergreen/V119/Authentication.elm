module Evergreen.V119.Authentication exposing (..)

import Dict
import Evergreen.V119.Credentials
import Evergreen.V119.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V119.User.User
    , credentials : Evergreen.V119.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
