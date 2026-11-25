// 가방 한 칸 (서버 GET /items 응답)
// type: EFFECT(내 공격 이펙트) / 나중에 MATERIAL(재료) 등
class ItemModel {
  final int id;
  final String type;
  final String itemKey; // EFFECT면 assets/images/effects/{itemKey}
  final String name;
  final String? description;
  final int? priceKrw; // null = 판매 안 함
  final String? productId; // Play 상품 ID (null = 결제 준비 전)
  final bool owned;
  final bool equipped;
  final int quantity;

  const ItemModel({
    required this.id,
    required this.type,
    required this.itemKey,
    required this.name,
    this.description,
    this.priceKrw,
    this.productId,
    required this.owned,
    required this.equipped,
    required this.quantity,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) => ItemModel(
        id: json['id'],
        type: json['type'] ?? 'EFFECT',
        itemKey: json['itemKey'] ?? '',
        name: json['name'] ?? '',
        description: json['description'],
        priceKrw: json['priceKrw'],
        productId: json['productId'],
        owned: json['owned'] == true,
        equipped: json['equipped'] == true,
        quantity: json['quantity'] ?? 0,
      );
}
