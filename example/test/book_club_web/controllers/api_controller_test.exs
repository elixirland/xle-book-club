defmodule XleBookClubWeb.APIControllerTest do
  use BookClubWeb.ConnCase, async: true
  import BookClub.Factory

  describe "GET /api/books" do
    test "successfully fetches books", %{conn: conn} do
      %{id: id} = insert!(:book)
      conn = get(conn, ~p"/api/books")

      assert body = json_response(conn, 200)
      assert [%{"book" => %{"id" => ^id}}] = body
    end

    test "successfully fetches books with a filter", %{conn: conn} do
      insert!(:book, title: "Blue")
      insert!(:book, title: "Red")
      insert!(:book, title: "Light blue")

      conn = get(conn, ~p"/api/books?title=blue")

      assert body = json_response(conn, 200)

      assert [
               %{"book" => %{"title" => "Blue"}},
               %{"book" => %{"title" => "Light blue"}}
             ] = body
    end

    test "successfully fetches all books when filter is empty", %{conn: conn} do
      insert!(:book, title: "Banana")
      insert!(:book, title: "Apple")
      insert!(:book, title: "Cranberry")

      conn = get(conn, ~p"/api/books?title=")

      assert body = json_response(conn, 200)
      # Verify that all titles are present, regardless of their order
      assert ["Apple", "Banana", "Cranberry"] ==
               body
               |> Enum.map(fn %{"book" => %{"title" => title}} -> title end)
               |> Enum.sort()
    end

    test "returns empty list when no books are found", %{conn: conn} do
      conn = get(conn, ~p"/api/books")
      assert json_response(conn, 200) == []
    end
  end

  describe "GET /api/books/:id" do
    test "successfully fetches a book", %{conn: conn} do
      book = %{id: book_id} = insert!(:book)
      conn = get(conn, ~p"/api/books/#{book.id}")
      assert %{"book" => %{"id" => ^book_id}} = json_response(conn, 200)
    end

    test "returns a 404 when the book does not exist", %{conn: conn} do
      conn = get(conn, ~p"/api/books/1")
      assert %{"error" => _} = json_response(conn, 404)
    end

    test "returns a bad request status when an invalid id is given", %{conn: conn} do
      invalid_ids = ["hi123", "0", "-1"]

      for id <- invalid_ids do
        conn = get(conn, ~p"/api/books/#{id}")
        assert %{"error" => _} = json_response(conn, :bad_request)
      end
    end

    test "fetches book with active page", %{conn: conn} do
      book = insert!(:book)
      active_page = insert!(:page, book_id: book.id, number: 1, status: :active)
      _other_page = insert!(:page, book_id: book.id, number: 2)

      conn = get(conn, ~p"/api/books/#{book.id}")

      assert json_response(conn, 200) == %{
               "book" => %{
                 "id" => book.id,
                 "title" => book.title
               },
               "page" => %{
                 "id" => active_page.id,
                 "content" => active_page.content,
                 "number" => active_page.number,
                 "status" => "active"
               }
             }
    end

    test "fetches book with first page", %{conn: conn} do
      book = insert!(:book)
      page_one = insert!(:page, book_id: book.id, number: 1)
      _page_two = insert!(:page, book_id: book.id, number: 2)
      _page_three = insert!(:page, book_id: book.id, number: 3)

      conn = get(conn, ~p"/api/books/#{book.id}")

      assert json_response(conn, 200) == %{
               "book" => %{
                 "id" => book.id,
                 "title" => book.title
               },
               "page" => %{
                 "id" => page_one.id,
                 "content" => page_one.content,
                 "number" => page_one.number,
                 "status" => "inactive"
               }
             }
    end

    test "fetches book that has no pages", %{conn: conn} do
      book = insert!(:book)
      conn = get(conn, ~p"/api/books/#{book.id}")

      assert json_response(conn, 200) == %{
               "book" => %{
                 "id" => book.id,
                 "title" => book.title
               },
               "page" => nil
             }
    end
  end
end
