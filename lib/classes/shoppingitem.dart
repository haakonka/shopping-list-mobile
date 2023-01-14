class ShoppingItem {
  late String item;
  late bool bought;
  ShoppingItem(this.item, this.bought);

  ShoppingItem.fromJson(json) {
    item = json['item'];
    if (json['bought'] == true) {
      bought = true;
    } else {
      bought = false;
    }
  }

  @override
  String toString() {
    String kjoptStatus = "Kjøpt";
    if (!bought) {
      kjoptStatus = "";
    }
    return "$item $kjoptStatus";
  }

  Map<String, dynamic> toJson() => {
        'item': item,
        'bought': bought,
      };
}
