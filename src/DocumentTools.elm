module DocumentTools exposing (..)

import Document exposing (Document)
import Time
import Types


sort : Types.SortMode -> List Document -> List Document
sort sortMode documents =
    let
        sort_ =
            case sortMode of
                Types.SortAlphabetically ->
                    List.sortBy (\doc -> doc.title)

                Types.SortByMostRecent ->
                    List.sortWith (\a b -> compare (Time.posixToMillis b.modified) (Time.posixToMillis a.modified))
    in
    sort_ documents
