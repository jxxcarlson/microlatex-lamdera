module Evergreen.V375.Compiler.DifferentialParser exposing (..)

import Evergreen.V375.Compiler.AbstractDifferentialParser
import Evergreen.V375.Compiler.Acc
import Evergreen.V375.Parser.Block
import Evergreen.V375.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V375.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V375.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V375.Parser.Block.ExpressionBlock) Evergreen.V375.Compiler.Acc.Accumulator
