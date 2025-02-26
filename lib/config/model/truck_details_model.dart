
class TripDetails {
   String? tripId;
   String? username;
   String? profile;
   String? truckNumber;
   String? doNumber;
   String? driverName;
   String? vendor;
   String? destinationFrom;
   String? destinationTo;
   String? truckType;
   String? transactionStatus;
   double? weight;
   double? actualWeight;
   double? differenceInWeight;
   double? freight;
   double? diesel;
   double? dieselAmount;
   String? dieselSlipNumber;
   double? tdsRate;
   double? advance;
   double? toll;
   double? adblue;
   double? greasing;
   // String? billId;
   Map<String, String?>? DieselSlipImage;
   Map<String, String?>? LoadingAdvice;
   Map<String, String?>? InvoiceCompany;
   Map<String, String?>? WeightmentSlip;
   String? id;
   DateTime? createdAt;
   DateTime? updatedAt;

   double? rate;
   String? billingId;
   double? amount;

  TripDetails({
    this.tripId,
    this.username,
    this.profile,
    this.truckNumber,
    this.doNumber,
    this.driverName,
    this.vendor,
    this.destinationFrom,
    this.destinationTo,
    this.truckType,
    this.transactionStatus,
    this.weight,
    this.actualWeight,
    this.differenceInWeight,
    this.freight,
    this.diesel,
    this.dieselAmount,
    this.dieselSlipNumber,
    this.tdsRate,
    this.advance,
    this.toll,
    this.adblue,
    this.greasing,
    // this.billId,
    this.DieselSlipImage,
    this.LoadingAdvice,
    this.InvoiceCompany,
    this.WeightmentSlip,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.rate,
    this.billingId,
    this.amount,
  });

  factory TripDetails.fromJson(Map<String, dynamic> json) {
    return TripDetails(
      tripId: json['TripID']?.toString(),
      username: json['Username']?.toString(),
      profile: json['Profile']?.toString(),
      truckNumber: json['TruckNumber']?.toString(),
      doNumber: json['DONumber']?.toString(),
      driverName: json['DriverName']?.toString(),
      vendor: json['Vendor']?.toString(),
      destinationFrom: json['DestinationFrom']?.toString(),
      destinationTo: json['DestinationTo']?.toString(),
      truckType: json['TruckType']?.toString(),
      transactionStatus: json['TransactionStatus']?.toString(),
      weight: json['Weight']?.toDouble(),
      actualWeight: json['ActualWeight']?.toDouble(),
      differenceInWeight: json['DifferenceInWeight']?.toDouble(),
      freight: json['Freight']?.toDouble(),
      diesel: json['Diesel']?.toDouble(),
      dieselAmount: json['DieselAmount']?.toDouble(),
      dieselSlipNumber: json['DieselSlipNumber']?.toString(),
      tdsRate: json['TDS_Rate']?.toDouble(),
      advance: json['Advance']?.toDouble(),
      toll: json['Toll']?.toDouble(),
      adblue: json['Adblue']?.toDouble(),
      greasing: json['Greasing']?.toDouble(),
      rate: json['rate']?.toDouble(),
      billingId: json['BillId']?.toString(),
      amount: double.tryParse(json['amount']?.toString() ?? '0'),
      DieselSlipImage: json['DieselSlipImage'] != null
          ? Map<String, String?>.from(json['DieselSlipImage'])
          : null,
      LoadingAdvice: json['LoadingAdvice'] != null
          ? Map<String, String?>.from(json['LoadingAdvice'])
          : null,
      InvoiceCompany: json['InvoiceCompany'] != null
          ? Map<String, String?>.from(json['InvoiceCompany'])
          : null,
      WeightmentSlip: json['WeightmentSlip'] != null
          ? Map<String, String?>.from(json['WeightmentSlip'])
          : null,
      id: json['_id'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (tripId != null) data['TripId'] = tripId;
    if (username != null) data['username'] = username;
    if (profile != null) data['userProfile'] = profile;
    if (truckNumber != null) data['TruckNumber'] = truckNumber;
    if (doNumber != null) data['DONumber'] = doNumber;
    if (driverName != null) data['DriverName'] = driverName;
    if (vendor != null) data['Vendor'] = vendor;
    if (destinationFrom != null) data['DestinationFrom'] = destinationFrom;
    if (destinationTo != null) data['DestinationTo'] = destinationTo;
    if (truckType != null) data['TruckType'] = truckType;
    if (transactionStatus != null) data['TransactionStatus'] = transactionStatus;
    if (weight != null) data['Weight'] = weight;
    if (actualWeight != null) data['ActualWeight'] = actualWeight;
    if (differenceInWeight != null) data['DifferenceInWeight'] = differenceInWeight;
    if (freight != null) data['Freight'] = freight;
    if (diesel != null) data['Diesel'] = diesel;
    if (dieselAmount != null) data['DieselAmount'] = dieselAmount;
    if (dieselSlipNumber != null) data['DieselSlipNumber'] = dieselSlipNumber;
    if (tdsRate != null) data['TDS_Rate'] = tdsRate;
    if (advance != null) data['Advance'] = advance;
    if (toll != null) data['Toll'] = toll;
    if (adblue != null) data['Adblue'] = adblue;
    if (greasing != null) data['Greasing'] = greasing;
    if (billingId != null) data['BillId'] = billingId;
    if (DieselSlipImage != null) data['DieselSlipImage'] = DieselSlipImage;
    if (LoadingAdvice != null) data['LoadingAdvice'] = LoadingAdvice;
    if (InvoiceCompany != null) data['InvoiceCompany'] = InvoiceCompany;
    if (WeightmentSlip != null) data['WeightmentSlip'] = WeightmentSlip;
    if (rate != null) data['rate'] = rate;
    if (amount != null) data['amount'] = amount;
    if (id != null) data['_id'] = id;
    return data;
  }
}
