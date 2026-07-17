// ponytail: curated registry keeps bundle small (no namespace import of ~2k icons).
// Expand ICON_OPTIONS / ICON_MAP together when adding a new consumables type.
import HelpOutline from '@mui/icons-material/HelpOutline';
import Restaurant from '@mui/icons-material/Restaurant';
import LocalPizza from '@mui/icons-material/LocalPizza';
import Cake from '@mui/icons-material/Cake';
import Cookie from '@mui/icons-material/Cookie';
import Icecream from '@mui/icons-material/Icecream';
import BakeryDining from '@mui/icons-material/BakeryDining';
import SetMeal from '@mui/icons-material/SetMeal';
import LunchDining from '@mui/icons-material/LunchDining';
import DinnerDining from '@mui/icons-material/DinnerDining';
import BreakfastDining from '@mui/icons-material/BreakfastDining';
import LocalDining from '@mui/icons-material/LocalDining';
import EmojiFoodBeverage from '@mui/icons-material/EmojiFoodBeverage';
import LocalCafe from '@mui/icons-material/LocalCafe';
import LocalBar from '@mui/icons-material/LocalBar';
import WineBar from '@mui/icons-material/WineBar';
import SportsBar from '@mui/icons-material/SportsBar';
import Liquor from '@mui/icons-material/Liquor';
import LocalDrink from '@mui/icons-material/LocalDrink';
import LocalFireDepartment from '@mui/icons-material/LocalFireDepartment';
import Whatshot from '@mui/icons-material/Whatshot';
import SoupKitchen from '@mui/icons-material/SoupKitchen';
import RamenDining from '@mui/icons-material/RamenDining';
import RiceBowl from '@mui/icons-material/RiceBowl';
import KebabDining from '@mui/icons-material/KebabDining';
import Fastfood from '@mui/icons-material/Fastfood';
import Egg from '@mui/icons-material/Egg';
import Scale from '@mui/icons-material/Scale';
import Park from '@mui/icons-material/Park';
import Spa from '@mui/icons-material/Spa';
import EnergySavingsLeaf from '@mui/icons-material/EnergySavingsLeaf';
import Star from '@mui/icons-material/Star';
import Favorite from '@mui/icons-material/Favorite';
import Bookmark from '@mui/icons-material/Bookmark';
import Home from '@mui/icons-material/Home';
import Inventory2 from '@mui/icons-material/Inventory2';
import Category from '@mui/icons-material/Category';
import Style from '@mui/icons-material/Style';
import LocalGroceryStore from '@mui/icons-material/LocalGroceryStore';
import ShoppingBasket from '@mui/icons-material/ShoppingBasket';
import Storefront from '@mui/icons-material/Storefront';
import Agriculture from '@mui/icons-material/Agriculture';
import LocalFlorist from '@mui/icons-material/LocalFlorist';
import FoodBank from '@mui/icons-material/FoodBank';
import OutdoorGrill from '@mui/icons-material/OutdoorGrill';
import WaterDrop from '@mui/icons-material/WaterDrop';
import type { SvgIconComponent } from '@mui/icons-material';

export interface IconOption {
  name: string;
  label: string;
}

export const ICON_OPTIONS: IconOption[] = [
  { name: 'LocalPizza', label: 'Pizza (Cheese)' },
  { name: 'WineBar', label: 'Wine' },
  { name: 'LocalCafe', label: 'Coffee' },
  { name: 'LocalFireDepartment', label: 'Hot Sauce' },
  { name: 'SportsBar', label: 'Beer' },
  { name: 'EmojiFoodBeverage', label: 'Tea' },
  { name: 'LocalFlorist', label: 'Apple' },
  { name: 'Cake', label: 'Cake' },
  { name: 'Cookie', label: 'Cookie' },
  { name: 'SetMeal', label: 'Fish' },
  { name: 'Restaurant', label: 'Salad' },
  { name: 'Icecream', label: 'Ice Cream' },
  { name: 'LunchDining', label: 'Lunch' },
  { name: 'DinnerDining', label: 'Dinner' },
  { name: 'BreakfastDining', label: 'Breakfast' },
  { name: 'LocalDining', label: 'Meal' },
  { name: 'Liquor', label: 'Spirits' },
  { name: 'LocalBar', label: 'Cocktail' },
  { name: 'LocalDrink', label: 'Drink' },
  { name: 'BakeryDining', label: 'Bakery' },
  { name: 'RamenDining', label: 'Noodles' },
  { name: 'RiceBowl', label: 'Rice' },
  { name: 'Fastfood', label: 'Fast Food' },
  { name: 'Egg', label: 'Egg' },
  { name: 'Whatshot', label: 'Spicy' },
  { name: 'KebabDining', label: 'Skewer' },
  { name: 'SoupKitchen', label: 'Soup' },
  { name: 'OutdoorGrill', label: 'Grill' },
  { name: 'FoodBank', label: 'Pantry' },
  { name: 'Agriculture', label: 'Farm' },
  { name: 'EnergySavingsLeaf', label: 'Herbal' },
  { name: 'Spa', label: 'Spa' },
  { name: 'Park', label: 'Natural' },
  { name: 'LocalGroceryStore', label: 'Grocery' },
  { name: 'ShoppingBasket', label: 'Basket' },
  { name: 'Storefront', label: 'Shop' },
  { name: 'Inventory2', label: 'Stock' },
  { name: 'Category', label: 'Category' },
  { name: 'Style', label: 'Style' },
  { name: 'Star', label: 'Star' },
  { name: 'Favorite', label: 'Favorite' },
  { name: 'Bookmark', label: 'Bookmark' },
  { name: 'WaterDrop', label: 'Liquid' },
  { name: 'Scale', label: 'Weight' },
  { name: 'Home', label: 'Home' },
];

const ICON_MAP: Record<string, SvgIconComponent> = {
  HelpOutline,
  Restaurant,
  LocalPizza,
  Cake,
  Cookie,
  Icecream,
  BakeryDining,
  SetMeal,
  LunchDining,
  DinnerDining,
  BreakfastDining,
  LocalDining,
  EmojiFoodBeverage,
  LocalCafe,
  LocalBar,
  WineBar,
  SportsBar,
  Liquor,
  LocalDrink,
  LocalFireDepartment,
  Whatshot,
  SoupKitchen,
  RamenDining,
  RiceBowl,
  KebabDining,
  Fastfood,
  Egg,
  Scale,
  Park,
  Spa,
  EnergySavingsLeaf,
  Star,
  Favorite,
  Bookmark,
  Home,
  Inventory2,
  Category,
  Style,
  LocalGroceryStore,
  ShoppingBasket,
  Storefront,
  Agriculture,
  LocalFlorist,
  FoodBank,
  OutdoorGrill,
};

export const FALLBACK_ICON: SvgIconComponent = HelpOutline;

export function resolveIcon(name?: string | null): SvgIconComponent {
  if (!name) return FALLBACK_ICON;
  return ICON_MAP[name] ?? FALLBACK_ICON;
}
