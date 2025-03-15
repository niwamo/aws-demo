package main

import (
	"fmt"
	"net/http"
	"log"
	"context"
	"time"
	"strings"
	"os"
	"html/template"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func getRootHandler(client *mongo.Client, tmpl *template.Template) http.HandlerFunc {
	return func(response http.ResponseWriter, request *http.Request) {
		if request.Method != "GET" {
			log.Printf("Received illegal %s request to /", request.Method)
			return
		}
		log.Print("Received request for /")
		
		collection := client.Database("aws-demo").Collection("docs")

		ctx, _ := context.WithTimeout(context.Background(), 10*time.Second)
		cursor, err := collection.Find(ctx, bson.D{})
		if err != nil {
			log.Fatal(err)
		}
		defer cursor.Close(ctx)

		var results []string

		for cursor.Next(ctx) {
			var document bson.D
			if err := cursor.Decode(&document); err != nil {
				log.Fatal(err)
			}
			results = append(results, fmt.Sprintf("%v", document))
		}

		result := strings.Join(results, "\n")

		data := map[string]string{
			"Bin": result,
		}
		err = tmpl.Execute(response, data)

		if err != nil {
			http.Error(response, err.Error(), http.StatusInternalServerError)
			return
		}
	}
}

func main() {
	log.Print("Starting server...")

	uri := os.Getenv("DB_CONN_STRING")
	log.Printf("DB_CONN_STRING: %s", uri)

	client, err := mongo.NewClient(options.Client().ApplyURI(uri))
	if err != nil {
		log.Fatal(err)
	}

	ctx, _ := context.WithTimeout(context.Background(), 10*time.Second)
	err = client.Connect(ctx)
	if err != nil {
		log.Fatal(err)
	}
	defer client.Disconnect(ctx)
	log.Print("Connected to database")

	tmpl, err := template.ParseFiles("/opt/index.html")
	if err != nil {
		log.Fatal(err)
	}

	getRoot := getRootHandler(client, tmpl)
	http.HandleFunc("/", getRoot)
	err = http.ListenAndServeTLS(":443", "/opt/cert.crt", "/opt/cert.key", nil)
	if err != nil {
		log.Fatal(err)
	}

	log.Print("Exiting.")
}