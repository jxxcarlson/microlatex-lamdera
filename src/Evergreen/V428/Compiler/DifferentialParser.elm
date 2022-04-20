module Evergreen.V428.Compiler.DifferentialParser exposing (..)

import Evergreen.V428.Compiler.AbstractDifferentialParser
import Evergreen.V428.Compiler.Acc
import Evergreen.V428.Parser.Block
import Evergreen.V428.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V428.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V428.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V428.Parser.Block.ExpressionBlock) Evergreen.V428.Compiler.Acc.Accumulator
