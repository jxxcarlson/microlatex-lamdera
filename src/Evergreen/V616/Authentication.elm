module Evergreen.V616.Authentication exposing (..)

import Dict
import Evergreen.V616.Credentials
import Evergreen.V616.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V616.User.User
    , credentials : Evergreen.V616.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
