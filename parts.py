import math

def fastner_default_cost(quantity: int) -> int:
    # Assume ~$2 USD for 10 for all fasteners.
    return 2 * math.ceil(quantity/10)

def rail_MGN9(quantity, length):
    return quantity * 20, None

def screw_M5_wafer_screw(quantity, length):
    return fastner_default_cost(quantity), "https://www.aliexpress.com/item/1005005070119421.html?spm=a2g0o.order_list.order_list_main.102.463c1802BoQpbq"

def screw_M3_cap_screw(quantity, length):
    return fastner_default_cost(quantity), None

def nut_M5_nut(quantity):
    return fastner_default_cost(quantity), None

def sliding_t_nut_M3_hammer_nut(quantity):
    return fastner_default_cost(quantity), None

def washer_M3_washer(quantity):
    return fastner_default_cost(quantity), None