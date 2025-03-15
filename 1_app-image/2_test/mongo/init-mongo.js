db.createUser({
  user: "aws-demo",
  pwd: "aws-demo",
  roles: ["dbOwner"]
});

db.docs.insertMany([
  { firstRecord: "firstValue" }
]);
