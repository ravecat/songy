import { render, screen, fireEvent } from "@testing-library/svelte";
import { expect, test, describe } from "vitest";
import TurnWaitingModal from "@components/TurnWaitingModal.svelte";

describe("TurnWaitingModal", () => {
  const mockChannelContext = {
    state: {
      turn: {
        queue: ["user-1", "user-2"],
        current_player_index: 0,
      },
      participants: [
        {
          uuid: "user-1",
          name: "Alice",
          avatar_url: "https://example.com/alice.jpg",
        },
        {
          uuid: "user-2",
          name: "Bob",
          avatar_url: "https://example.com/bob.jpg",
        },
      ],
    },
  };

  test("renders modal when isOpen is true", () => {
    const mockClose = () => {};

    render(TurnWaitingModal, {
      props: {
        isOpen: true,
        close: mockClose,
      },
      context: new Map([["channel", mockChannelContext]]),
    });

    expect(screen.getByText("Alice turn")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Ready?" })).toBeInTheDocument();
  });

  test("does not render modal when isOpen is false", () => {
    const mockClose = () => {};

    render(TurnWaitingModal, {
      props: {
        isOpen: false,
        close: mockClose,
      },
      context: new Map([["channel", mockChannelContext]]),
    });

    expect(screen.queryByText("Alice turn")).not.toBeInTheDocument();
  });

  test("calls close function when Ready button is clicked", async () => {
    let closeCalled = false;
    const mockClose = () => {
      closeCalled = true;
    };

    render(TurnWaitingModal, {
      props: {
        isOpen: true,
        close: mockClose,
      },
      context: new Map([["channel", mockChannelContext]]),
    });

    const button = screen.getByRole("button", { name: "Ready?" });
    await fireEvent.click(button);

    expect(closeCalled).toBe(true);
  });

  test("has correct accessibility attributes", () => {
    const mockClose = () => {};

    render(TurnWaitingModal, {
      props: {
        isOpen: true,
        close: mockClose,
      },
      context: new Map([["channel", mockChannelContext]]),
    });

    const dialog = screen.getByRole("dialog", { hidden: true });
    expect(dialog).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Ready?" })).toBeInTheDocument();
  });

  test("dialog element is present when modal is open", () => {
    const mockClose = () => {};

    render(TurnWaitingModal, {
      props: {
        isOpen: true,
        close: mockClose,
      },
      context: new Map([["channel", mockChannelContext]]),
    });

    expect(screen.getByRole("dialog", { hidden: true })).toBeInTheDocument();
  });

  test("dialog element is not present when modal is closed", () => {
    const mockClose = () => {};

    render(TurnWaitingModal, {
      props: {
        isOpen: false,
        close: mockClose,
      },
      context: new Map([["channel", mockChannelContext]]),
    });

    expect(
      screen.queryByRole("dialog", { hidden: true })
    ).not.toBeInTheDocument();
  });

  test("button has autofocus attribute", () => {
    const mockClose = () => {};

    render(TurnWaitingModal, {
      props: {
        isOpen: true,
        close: mockClose,
      },
      context: new Map([["channel", mockChannelContext]]),
    });

    const button = screen.getByRole("button", { name: "Ready?" });
    expect(button).toHaveAttribute("autofocus");
  });

  test("dialog can be closed by clicking outside", async () => {
    let closeCalled = false;
    const mockClose = () => {
      closeCalled = true;
    };

    render(TurnWaitingModal, {
      props: {
        isOpen: true,
        close: mockClose,
      },
      context: new Map([["channel", mockChannelContext]]),
    });

    const dialog = screen.getByRole("dialog", { hidden: true });

    // Simulate clicking on the dialog backdrop (the dialog element itself)
    await fireEvent.click(dialog);

    expect(closeCalled).toBe(true);
  });

  test("dialog does not close when clicking inside content", async () => {
    let closeCalled = false;
    const mockClose = () => {
      closeCalled = true;
    };

    render(TurnWaitingModal, {
      props: {
        isOpen: true,
        close: mockClose,
      },
      context: new Map([["channel", mockChannelContext]]),
    });

    const heading = screen.getByText("Alice turn");
    await fireEvent.click(heading);

    expect(closeCalled).toBe(false);
  });

  test("modal has correct heading hierarchy", () => {
    const mockClose = () => {};

    render(TurnWaitingModal, {
      props: {
        isOpen: true,
        close: mockClose,
      },
      context: new Map([["channel", mockChannelContext]]),
    });

    expect(screen.getByRole("heading", { level: 2 })).toHaveTextContent(
      "Alice turn"
    );
  });

  test("displays player avatar and information", () => {
    const mockClose = () => {};

    render(TurnWaitingModal, {
      props: {
        isOpen: true,
        close: mockClose,
      },
      context: new Map([["channel", mockChannelContext]]),
    });

    const avatar = screen.getByAltText("Alice");
    expect(avatar).toBeInTheDocument();
    expect(avatar).toHaveAttribute("src", "https://example.com/alice.jpg");
    expect(screen.getByText("Alice turn")).toBeInTheDocument();
  });
});
