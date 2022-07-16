module Evergreen.V704.Authentication exposing (..)

import Dict
import Evergreen.V704.Credentials
import Evergreen.V704.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V704.User.User
    , credentials : Evergreen.V704.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
