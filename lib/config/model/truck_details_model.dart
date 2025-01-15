class TripDetails {
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
   String? billId;
   Map<String, String?>? dieselSlipImage;
   Map<String, String?>? loadingAdvice;
   Map<String, String?>? invoiceCompany;
   Map<String, String?>? weightmentSlip;
   String? id;
   DateTime? createdAt;
   DateTime? updatedAt;

  TripDetails({
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
    this.billId,
    this.dieselSlipImage,
    this.loadingAdvice,
    this.invoiceCompany,
    this.weightmentSlip,
    this.id,
    this.createdAt,
    this.updatedAt,
  });

  factory TripDetails.fromJson(Map<String, dynamic> json) {
    return TripDetails(
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
      billId: json['BillId']?.toString(),
      dieselSlipImage: json['DieselSlipImage'] != null
          ? Map<String, String?>.from(json['DieselSlipImage'])
          : null,
      loadingAdvice: json['LoadingAdvice'] != null
          ? Map<String, String?>.from(json['LoadingAdvice'])
          : null,
      invoiceCompany: json['InvoiceCompany'] != null
          ? Map<String, String?>.from(json['InvoiceCompany'])
          : null,
      weightmentSlip: json['WeightmentSlip'] != null
          ? Map<String, String?>.from(json['WeightmentSlip'])
          : null,
      id: json['_id']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
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
    if (billId != null) data['BillId'] = billId;
    if (dieselSlipImage != null) data['DieselSlipImage'] = dieselSlipImage;
    if (loadingAdvice != null) data['LoadingAdvice'] = loadingAdvice;
    if (invoiceCompany != null) data['InvoiceCompany'] = invoiceCompany;
    if (weightmentSlip != null) data['WeightmentSlip'] = weightmentSlip;
    return data;
  }
}
